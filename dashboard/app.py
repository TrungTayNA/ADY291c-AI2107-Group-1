import os

import joblib
import pandas as pd
import streamlit as st

st.set_page_config(
    page_title="Dự đoán nguy cơ đánh giá thấp - Olist",
    page_icon="🤖",
    layout="centered",
)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(
    BASE_DIR,
    "Notebooks Project",
    "4_REGRESSION ANALYSIS AND MACHINE LEARNING PREDICTION",
)

MODEL_FILES = {
    "Trước khi giao hàng": "review_model_at_purchase.joblib",
    "Sau khi giao hàng": "review_model_post_delivery.joblib",
}


@st.cache_resource(show_spinner="Đang nạp mô hình dự đoán...")
def load_review_model(model_filename):
    model_path = os.path.join(MODEL_DIR, model_filename)
    if not os.path.isfile(model_path):
        raise FileNotFoundError(f"Không tìm thấy mô hình dự đoán tại {model_path}.")

    artifact = joblib.load(model_path)
    if not isinstance(artifact, dict):
        raise TypeError(f"Mô hình tại {model_path} không có định dạng hợp lệ.")
    if not all(key in artifact for key in ("model", "threshold", "columns")):
        raise ValueError(f"Mô hình tại {model_path} thiếu thông tin cần thiết.")
    if not hasattr(artifact["model"], "predict_proba"):
        raise TypeError(f"Mô hình tại {model_path} không hỗ trợ dự đoán xác suất.")
    return artifact


def get_customer_states(model):
    preprocessor = model.named_steps.get("pre")
    if preprocessor is None:
        raise ValueError("Mô hình thiếu bước xử lý đặc trưng phân loại.")

    for _, transformer, columns in preprocessor.transformers_:
        if "customer_state" not in columns:
            continue
        if not hasattr(transformer, "categories_"):
            raise TypeError("Mô hình không có danh sách bang khách hàng đã huấn luyện.")
        state_index = columns.index("customer_state")
        return sorted(str(state) for state in transformer.categories_[state_index])

    raise ValueError("Mô hình không có đặc trưng customer_state.")


st.title("🤖 Dự đoán nguy cơ đánh giá thấp")
st.write(
    "Ước tính nguy cơ một đơn hàng nhận review **1–2 sao**. "
    "Kết quả là xác suất và phân loại nguy cơ, không phải dự đoán chính xác số sao 1–5."
)

prediction_timing = st.radio(
    "Thời điểm dự đoán",
    list(MODEL_FILES),
    horizontal=True,
)
artifact = load_review_model(MODEL_FILES[prediction_timing])
model = artifact["model"]
model_columns = artifact["columns"]
customer_states = get_customer_states(model)
threshold = float(artifact["threshold"])
st.caption(f"Random Forest · Ngưỡng phân loại nguy cơ: {threshold:.2f}")

with st.form("review_risk_prediction_form"):
    order_details, order_value = st.columns(2)
    with order_details:
        purchase_hour = st.slider("Giờ đặt hàng", min_value=0, max_value=23, value=12)
        purchase_month = st.slider("Tháng đặt hàng", min_value=1, max_value=12, value=6)
        state_default = customer_states.index("SP") if "SP" in customer_states else 0
        customer_state = st.selectbox(
            "Bang khách hàng", customer_states, index=state_default
        )
        item_count = st.number_input(
            "Số sản phẩm trong đơn", min_value=1, max_value=100, value=1
        )
        distinct_products = st.number_input(
            "Số loại sản phẩm khác nhau", min_value=1, max_value=100, value=1
        )
        seller_count = st.number_input("Số người bán", min_value=1, max_value=100, value=1)

    with order_value:
        total_item_price = st.number_input(
            "Tổng tiền sản phẩm (BRL)", min_value=0.0, value=100.0, step=10.0
        )
        total_freight = st.number_input(
            "Tổng phí vận chuyển (BRL)", min_value=0.0, value=20.0, step=1.0
        )
        total_paid = st.number_input(
            "Tổng thanh toán (BRL)", min_value=0.0, value=120.0, step=10.0
        )
        max_installments = st.number_input(
            "Số kỳ thanh toán tối đa", min_value=0, max_value=36, value=1
        )

        delivery_features = {}
        if prediction_timing == "Sau khi giao hàng":
            delivery_features = {
                "delivery_days": st.number_input(
                    "Số ngày giao thực tế", min_value=0.0, value=15.0, step=1.0
                ),
                "estimated_days": st.number_input(
                    "Số ngày giao dự kiến", min_value=0.0, value=12.0, step=1.0
                ),
                "delay_days": st.number_input(
                    "Số ngày chênh lệch so với ngày hẹn",
                    min_value=-365,
                    max_value=365,
                    value=0,
                    help="Số âm là giao sớm, số dương là giao trễ.",
                ),
                "is_late": int(
                    st.checkbox(
                        "Đơn được giao sau ngày dự kiến",
                        help="Đối chiếu ngày giao thực tế với ngày giao dự kiến.",
                    )
                ),
            }

    submitted = st.form_submit_button(
        "Dự đoán nguy cơ review",
        type="primary",
        width="stretch",
    )

if submitted:
    features = {
        "purchase_hour": purchase_hour,
        "purchase_month": purchase_month,
        "customer_state": customer_state,
        "item_count": item_count,
        "distinct_products": distinct_products,
        "seller_count": seller_count,
        "total_item_price": total_item_price,
        "total_freight": total_freight,
        "freight_to_price_pct": (
            round(100.0 * total_freight / total_item_price, 2)
            if total_item_price > 0
            else 0.0
        ),
        "total_paid": total_paid,
        "max_installments": max_installments,
        **delivery_features,
    }

    missing_features = [name for name in model_columns if name not in features]
    if missing_features:
        raise ValueError(
            f"Thiếu đặc trưng đầu vào của mô hình: {', '.join(missing_features)}."
        )

    input_row = pd.DataFrame(
        [[features[name] for name in model_columns]],
        columns=model_columns,
    )
    classes = list(model.classes_)
    if 1 not in classes:
        raise ValueError("Mô hình không có lớp mục tiêu nguy cơ review thấp (1).")

    risk_probability = float(model.predict_proba(input_row)[0, classes.index(1)])
    is_high_risk = risk_probability >= threshold
    result_columns = st.columns(2)
    result_columns[0].metric("Xác suất review 1–2 sao", f"{risk_probability:.1%}")
    result_columns[1].metric(
        "Phân loại của mô hình",
        "Nguy cơ cao" if is_high_risk else "Nguy cơ thấp",
        f"Ngưỡng: {threshold:.2f}",
    )
    st.progress(risk_probability)

    if is_high_risk:
        st.warning(
            "Đơn hàng có nguy cơ nhận đánh giá thấp theo ngưỡng của mô hình. "
            "Nên ưu tiên theo dõi trải nghiệm giao hàng và hỗ trợ khách hàng."
        )
    else:
        st.success("Mô hình chưa xếp đơn hàng vào nhóm nguy cơ review thấp.")

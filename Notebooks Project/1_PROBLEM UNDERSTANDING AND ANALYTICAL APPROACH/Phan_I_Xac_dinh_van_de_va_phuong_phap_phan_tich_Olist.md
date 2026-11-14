# I. XÁC ĐỊNH VẤN ĐỀ VÀ PHƯƠNG PHÁP PHÂN TÍCH

## 1. Phát biểu vấn đề (Problem Statement)

### Bối cảnh dự án (Project Context)

Dự án tập trung vào lĩnh vực **Thương mại điện tử (E-commerce)**, sử dụng bộ dữ liệu Brazilian E-Commerce Public Dataset by Olist. Olist là một nền tảng marketplace trực tuyến kết nối khách hàng với người bán. Bộ dữ liệu cung cấp thông tin về đơn hàng, các sản phẩm trong đơn hàng và đánh giá của khách hàng. Những thông tin này cho phép chúng ta phân tích mối liên hệ giữa quá trình hoàn tất đơn hàng và mức độ hài lòng của khách hàng.

Trong lĩnh vực thương mại điện tử, sự hài lòng của khách hàng đóng vai trò quan trọng. Khách hàng không chỉ đánh giá sản phẩm đã mua mà còn đánh giá toàn bộ trải nghiệm mua sắm. Hiệu quả giao hàng và đặc điểm của đơn hàng có thể có mối liên hệ với cách khách hàng đánh giá trải nghiệm của họ.

### Xác định vấn đề kinh doanh / thực tiễn (Business / Real-World Problem Identification)

Một thách thức thực tiễn trong thương mại điện tử là nhận diện những đơn hàng có khả năng nhận được phản hồi tiêu cực từ khách hàng. Việc giao hàng trễ có thể gây bất tiện cho khách hàng, trong khi số lượng sản phẩm trong một đơn hàng có thể liên quan đến mức độ phức tạp của quá trình xử lý đơn hàng. Những yếu tố này có thể có mối liên hệ với kết quả đánh giá của khách hàng.

Dự án tập trung giải quyết câu hỏi phân tích sau:

**Liệu thời gian giao hàng trễ và số lượng sản phẩm trong một đơn hàng có thể được sử dụng để nhận diện và dự đoán khả năng đơn hàng nhận được đánh giá thấp từ khách hàng hay không?**

Trong dự án này, đánh giá thấp được định nghĩa là điểm đánh giá bằng **1 hoặc 2**, trong khi điểm đánh giá từ **3 đến 5** được xếp vào nhóm không đánh giá thấp. Vì vậy, biến mục tiêu `low_review` được xác định như sau:

- `low_review = 1` khi `review_score <= 2`.
- `low_review = 0` khi `review_score >= 3`.

Dự án sử dụng ba bảng dữ liệu nguồn: `orders`, `order_items` và `order_reviews`. Các bảng này được kết hợp ở cấp độ đơn hàng. Sau đó, hai biến đầu vào được tạo ra:

- `delay_days`: số ngày chênh lệch giữa ngày giao hàng thực tế và ngày giao hàng dự kiến. Giá trị dương thể hiện giao hàng trễ; giá trị bằng 0 thể hiện giao đúng ngày dự kiến; giá trị âm thể hiện giao hàng sớm.
- `item_count`: tổng số sản phẩm thuộc một đơn hàng.

Thời điểm dự đoán được xác định là **sau khi đơn hàng đã được giao nhưng trước khi khách hàng gửi đánh giá**. Vì vậy, `review_score` chỉ được sử dụng để tạo biến mục tiêu, không được sử dụng làm biến đầu vào của mô hình.

### Ý nghĩa của vấn đề (Significance of the Problem)

Việc nhận diện những đơn hàng có khả năng nhận được đánh giá thấp có thể cung cấp thông tin hữu ích cho hoạt động vận hành thương mại điện tử. Kết quả phân tích có thể hỗ trợ doanh nghiệp:

- Theo dõi hiệu quả giao hàng và tìm hiểu liệu việc giao hàng trễ có liên quan đến phản hồi tiêu cực của khách hàng hay không.
- Kiểm tra liệu các đơn hàng có số lượng sản phẩm khác nhau có tỷ lệ đánh giá thấp khác nhau hay không.
- Nhận diện những đặc điểm đơn hàng có thể giúp doanh nghiệp ưu tiên chăm sóc khách hàng sau khi giao hàng.
- Sử dụng kết quả dự đoán như một nguồn thông tin hỗ trợ ra quyết định nhằm cải thiện trải nghiệm khách hàng.

Dự án không mặc định rằng việc giao hàng trễ hoặc số lượng sản phẩm là nguyên nhân trực tiếp dẫn đến đánh giá thấp. Thay vào đó, dự án tập trung xem xét liệu các biến này có mối liên hệ với đánh giá thấp và có cung cấp thông tin hữu ích cho việc dự đoán hay không.

## 2. Mục tiêu dự án (Project Objectives)

### Mục tiêu tổng quát (General Objective)

Phân tích các yếu tố có liên quan đến kết quả đánh giá của khách hàng trong bộ dữ liệu thương mại điện tử Olist, đồng thời xây dựng một mô hình phân loại bằng Machine Learning nhằm dự đoán liệu một đơn hàng đã giao có khả năng nhận được đánh giá thấp hay không, dựa trên thời gian giao hàng trễ và số lượng sản phẩm trong đơn hàng.

### Mục tiêu cụ thể (Detailed Objectives)

1. **Thu thập và tiền xử lý dữ liệu**
   - Trích xuất các thuộc tính cần thiết từ ba bảng `orders`, `order_items` và `order_reviews`.
   - Kết hợp dữ liệu ở cấp độ đơn hàng, đồng thời tránh tạo ra các bản ghi trùng lặp do mối quan hệ một-nhiều giữa các bảng.
   - Xử lý các giá trị thiếu và bản ghi không hợp lệ khi cần thiết.
   - Tính toán `delay_days`, `item_count` và xây dựng biến mục tiêu `low_review`.

2. **Thực hiện phân tích dữ liệu bằng SQL**
   - Khảo sát phân phối điểm đánh giá của khách hàng và tỷ lệ đánh giá thấp.
   - So sánh tỷ lệ đánh giá thấp giữa nhóm đơn hàng giao trễ và nhóm đơn hàng giao đúng hoặc sớm hơn ngày dự kiến.
   - So sánh tỷ lệ đánh giá thấp giữa các nhóm đơn hàng có số lượng sản phẩm khác nhau.
   - Sử dụng kết quả truy vấn để nhận diện những xu hướng cần được phân tích sâu hơn.

3. **Phân tích dữ liệu và trực quan hóa bằng Python**
   - Khảo sát phân phối của thời gian giao hàng trễ, số lượng sản phẩm và điểm đánh giá.
   - Trực quan hóa mối quan hệ giữa thời gian giao hàng trễ và điểm đánh giá.
   - So sánh tỷ lệ đánh giá thấp giữa các nhóm trạng thái giao hàng và nhóm số lượng sản phẩm.
   - Khảo sát hệ số tương quan giữa các biến số được lựa chọn.
   - Sử dụng kết quả phân tích để giải thích cơ sở lựa chọn các biến đầu vào ban đầu cho mô hình.

4. **Xây dựng các mô hình Machine Learning**
   - Xác định `delay_days` và `item_count` là các biến đầu vào (`X`), và `low_review` là biến mục tiêu (`y`).
   - Chia dữ liệu thành tập huấn luyện (Training Set) và tập kiểm tra (Testing Set).
   - Xây dựng Logistic Regression làm mô hình cơ sở (Baseline Model).
   - Xây dựng Random Forest Classifier làm mô hình ứng viên chính.

5. **Đánh giá và diễn giải hiệu suất mô hình**
   - Đánh giá các mô hình bằng những chỉ số phân loại phù hợp, bao gồm Accuracy, Precision, Recall, Macro-F1 và PR-AUC.
   - So sánh các mô hình trên cùng một tập kiểm tra.
   - Phân tích Confusion Matrix và xác định mô hình phù hợp hơn trong việc nhận diện các đơn hàng có đánh giá thấp.
   - Phân tích Feature Importance để tìm hiểu mức độ đóng góp của các biến đầu vào đã lựa chọn.

6. **Tổng hợp kết quả và hạn chế**
   - Trình bày những xu hướng chính được phát hiện thông qua SQL Analysis, Python Visualization và Machine Learning.
   - Thảo luận cách kết quả có thể hỗ trợ việc theo dõi hoạt động giao hàng và cải thiện trải nghiệm khách hàng.
   - Xác định những hạn chế do chỉ sử dụng hai biến đầu vào, đồng thời đề xuất các biến bổ sung cho những nghiên cứu tiếp theo.

## 3. Phương pháp phân tích (Analytical Approach)

### Các loại phân tích được sử dụng (Type of Analysis)

Dự án kết hợp ba phương pháp phân tích chính: **Descriptive Analysis, Diagnostic Analysis và Predictive Analysis**.

#### 3.1. Phân tích mô tả (Descriptive Analysis)

Descriptive Analysis được sử dụng để tóm tắt và tìm hiểu dữ liệu lịch sử trong bộ dữ liệu Olist. SQL và Python được áp dụng để khảo sát:

- Phân phối điểm đánh giá và tỷ lệ đánh giá thấp.
- Phân phối thời gian giao hàng trễ.
- Số lượng sản phẩm trong mỗi đơn hàng.
- Tỷ lệ đánh giá thấp theo trạng thái giao hàng và nhóm số lượng sản phẩm.

Các biểu đồ trực quan hóa dữ liệu, bao gồm Box Plot, Bar Chart và Correlation Heatmap, giúp thể hiện phân phối và các xu hướng trong dữ liệu.

#### 3.2. Phân tích chẩn đoán (Diagnostic Analysis)

Diagnostic Analysis được sử dụng để tìm hiểu liệu thời gian giao hàng trễ và số lượng sản phẩm có mối liên hệ với kết quả đánh giá của khách hàng hay không. Dự án so sánh điểm đánh giá và tỷ lệ đánh giá thấp giữa các nhóm dữ liệu phù hợp.

Một số câu hỏi phân tích được đặt ra:

- Các đơn hàng giao trễ có tỷ lệ đánh giá thấp cao hơn các đơn hàng được giao đúng hoặc sớm hơn ngày dự kiến hay không?
- Các đơn hàng có số lượng sản phẩm khác nhau có tỷ lệ đánh giá thấp khác nhau hay không?
- Có thể quan sát thấy mối quan hệ nào giữa thời gian giao hàng trễ và điểm đánh giá hay không?

Kết quả truy vấn SQL và biểu đồ trực quan cung cấp bằng chứng mang tính khám phá để xem xét các câu hỏi này. Tuy nhiên, tương quan hoặc sự khác biệt giữa các nhóm không thể được xem là bằng chứng chứng minh quan hệ nhân quả. Nếu muốn đưa ra kết luận thống kê chính thức, cần sử dụng các kiểm định thống kê phù hợp.

#### 3.3. Phân tích dự đoán (Predictive Analysis)

Predictive Analysis được sử dụng để ước lượng khả năng một đơn hàng đã giao sẽ nhận được đánh giá thấp từ khách hàng. Biến mục tiêu `low_review` là biến phân loại nhị phân (Binary Classification), gồm hai giá trị:

- `1`: Đánh giá thấp (`review_score <= 2`).
- `0`: Không đánh giá thấp (`review_score >= 3`).

Dự án sử dụng hai thuật toán phân loại:

- **Logistic Regression**: được sử dụng làm mô hình cơ sở (Baseline Model) vì đây là phương pháp phân loại tương đối đơn giản và dễ diễn giải.
- **Random Forest Classifier**: được sử dụng làm mô hình ứng viên chính vì có khả năng nắm bắt các mối quan hệ phi tuyến và tương tác giữa các biến đầu vào.

Cả hai mô hình đều sử dụng cùng các biến đầu vào (`delay_days` và `item_count`) và được đánh giá trên cùng một tập kiểm tra độc lập. Hiệu suất của hai mô hình được so sánh bằng các chỉ số đánh giá phân loại, đặc biệt chú ý đến khả năng nhận diện các đơn hàng có đánh giá thấp.

### Lý do lựa chọn phương pháp (Justification)

Việc kết hợp các phương pháp phân tích trên là phù hợp vì dự án có hai mục tiêu liên quan với nhau: tìm hiểu các xu hướng đánh giá của khách hàng trong dữ liệu lịch sử và dự đoán kết quả đánh giá cho các đơn hàng đã giao.

- **Descriptive Analysis** giúp hiểu tổng quan bộ dữ liệu và tóm tắt đặc điểm về đánh giá, giao hàng và số lượng sản phẩm trong đơn hàng.
- **Diagnostic Analysis** tìm hiểu liệu thời gian giao hàng trễ và số lượng sản phẩm có mối liên hệ với đánh giá thấp hay không. Kết quả cung cấp cơ sở dữ liệu để giải thích việc lựa chọn các biến đầu vào ban đầu.
- **Predictive Analysis** mở rộng từ việc mô tả các xu hướng lịch sử sang đánh giá khả năng phân loại đơn hàng thành hai nhóm: đánh giá thấp và không đánh giá thấp.

Việc sử dụng SQL cho các truy vấn dữ liệu có cấu trúc và Python cho trực quan hóa cũng như xây dựng mô hình Machine Learning phù hợp với quy trình phân tích của dự án. So sánh Logistic Regression với Random Forest giúp đánh giá liệu một mô hình linh hoạt hơn có đạt hiệu suất dự đoán tốt hơn so với mô hình cơ sở hay không.

Phạm vi dự đoán của dự án được giới hạn ở hai biến đầu vào. Vì vậy, mô hình nên được xem là một nghiên cứu dự đoán ban đầu, không phải lời giải thích toàn diện cho sự hài lòng của khách hàng. Những yếu tố khác như chất lượng sản phẩm, danh mục sản phẩm, hiệu suất người bán, giá sản phẩm, phí vận chuyển và đặc điểm khách hàng cũng có thể ảnh hưởng đến kết quả đánh giá, nhưng chưa nằm trong phạm vi biến đầu vào của mô hình hiện tại.

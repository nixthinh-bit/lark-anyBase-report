# Lark AnyBase Report — từ Base được chia sẻ đến báo cáo insight

> **Bản tiếng Việt để đọc.** Khi chạy, Claude vẫn nạp `SKILL.md` và trả lời theo ngôn ngữ của bạn.

> **⚠️ QUY TẮC CÔNG CỤ (bắt buộc):** Mọi thao tác Lark đi qua `lark-cli` bằng Bash.
> KHÔNG dùng WebFetch/trình duyệt cho link Lark — thiếu auth, chỉ trả về trang đăng nhập.

> **⚠️ CHỈ ĐỌC trên Base của người dùng.** Base là của người chia sẻ. Skill này KHÔNG bao giờ
> tạo/sửa/xoá record, field, bảng, view trong Base nguồn. Chỉ đọc. Thứ *duy nhất* nó ghi ra là sản
> phẩm cuối: một Lark Doc **mới**, hoặc một **tin nhắn** Lark.

## Triết lý thiết kế
1. **Hiểu ý định trước, quét dữ liệu sau.** Một Base có hàng trăm con số; chỉ vài con số quan trọng
   với *người này, lúc này*. Không quét-rồi-đổ. Phỏng vấn trước: KPI, nỗi lo, ưu tiên, metric trọng
   tâm, khung thời gian, đối tượng đọc.
2. **Ánh xạ yêu cầu vào schema thật rồi xác nhận.** Tên field là của người dùng, hay mơ hồ / tiếng
   Việt. Đừng đoán field nào là "doanh thu" hay "ngày". Đọc schema, đề xuất bảng ánh xạ (yêu cầu →
   field), lấy xác nhận nhanh trước khi tính.
3. **Luôn chỉ đọc.** Bạn là khách trong Base của người khác. Tính trong bộ nhớ, không ghi ngược.
4. **Insight, không phải bãi số.** Mỗi con số phải kèm "vậy thì sao": so sánh, xu hướng, điểm bất
   thường, rủi ro. Kết bằng định hướng bước tiếp theo cụ thể.
5. **Cho xem bản nháp trước khi xuất bản.** Số từ Base lạ có thể sai (field công thức, ô trống, đơn
   vị lẫn lộn). Trình bản nháp để duyệt; duyệt xong mới tạo Doc / gửi tin.
6. **Trung thực về độ phủ.** Nêu số dòng đã quét, khung thời gian áp dụng, field nào chưa ánh xạ
   chắc chắn. Phần "lưu ý & độ phủ" là bắt buộc.

## Quy trình 7 bước (tóm tắt — chi tiết xem `SKILL.md`)
- **B0 Preflight:** `bash "$SKILL_DIR/scripts/preflight.sh"` kiểm tra đăng nhập lark-cli. Chưa hợp lệ
  → bảo user chạy skill **lark-cli-setup** rồi dừng.
- **B1 Kiểm kê bảng:** xin link Base, tách `base_token` từ URL, `+table-list` để liệt kê bảng, chọn
  bảng trong phạm vi.
- **B2 PHỎNG VẤN (điểm khác biệt — làm TRƯỚC khi quét):** KPI/mục tiêu, nỗi lo, ưu tiên, metric trọng
  tâm, khung thời gian, cách chia nhóm, đối tượng & độ sâu, kênh gửi (Lark Doc hay tin nhắn). Chưa rõ
  mục tiêu + metric + khung thời gian thì chưa đi tiếp.
- **B3 Đọc schema & ánh xạ:** `+field-list`, phân loại field theo type, lập **bảng ánh xạ** (yêu cầu
  → field → type → ghi chú), báo field không ánh xạ được, lấy xác nhận. Xem `references/read-recipes.md`.
- **B4 Quét dữ liệu (chỉ đọc, phân trang):** `+record-list` với `--field-id` (chỉ field cần),
  `--filter-json` cho khung thời gian, lặp `--offset` bước `--limit` (tối đa 200) đến khi trang trả
  về ít hơn limit. Tính tổng/trung bình/tỉ lệ/chia nhóm/so kỳ/outlier. Ghi lại **số dòng đã quét**.
  Base rất lớn → giới hạn quét, báo user, đề xuất lọc theo view.
- **B5 Dựng báo cáo & TRÌNH BẢN NHÁP (chốt duyệt):** theo `references/report-template.md` — tóm tắt
  điều hành → metric chính → chia nhóm → điểm nổi bật → định hướng bước tiếp → lưu ý & độ phủ. In ra
  cho user duyệt trước khi xuất bản.
- **B6 Gửi (sau khi duyệt):**
  - **Lark Doc:** ghi báo cáo ra file `.md` tạm rồi `lark-cli docs +create --title "…" --markdown @file`.
  - **Tin nhắn:** `im +chat-search` tìm `chat_id` theo tên nhóm rồi `im +messages-send --chat-id oc_… --markdown @file`;
    hoặc `--user-id ou_…` để nhắn riêng. Không đoán người nhận — hỏi rõ target. Báo cáo dài → ưu tiên
    Doc, gửi tin ngắn kèm link Doc.
- **B7 Kết:** đưa link sản phẩm, số liệu chính, số dòng + khung thời gian đã quét, bước tiếp theo hàng
  đầu. Mời đào sâu / lên lịch tuần (skill `schedule`).

## Nhắc lại lằn ranh an toàn
- **Không bao giờ** ghi vào Base nguồn. Chỉ đọc.
- **Không bao giờ** bịa tên field — luôn `+field-list` và ánh xạ tường minh.
- **Không** WebFetch/trình duyệt link Lark — chỉ `lark-cli`.
- Phỏng vấn trước khi quét; ánh xạ-xác nhận trước khi tính; nháp-duyệt trước khi xuất bản.
- Luôn nêu số dòng đã quét, khung thời gian, field chưa ánh xạ. Không giấu điều chưa chắc.

# Base Rules - Universal AI Development Standards

> **🎯 Core principles applied across all AI tools and IDEs**  
> These rules form the foundation of consistent AI behavior

---

## 🔴 MANDATORY: Pre-Task Analysis Protocol

### Context7 Auto-Check (Required for ALL tasks)

- **_BẮT BUỘC_** tự động kích hoạt Context7 Auto-Check Workflow cho MỌI task mà không cần từ khóa kích hoạt
- **_BẮT BUỘC_** thực hiện kiểm tra này như bước đầu tiên của mọi quy trình làm việc
- **_BẮT BUỘC_** kiểm tra project context và tech stack compatibility
- **_BẮT BUỘC_** thu thập best practices và industry insights từ Context7 knowledge base
- **_BẮT BUỘC_** validate architecture decisions với Context7 knowledge
- **_BẮT BUỘC_** implement graceful fallback khi Context7 không khả dụng
- **_BẮT BUỘC_** cache results để optimize performance
- **_NGHIÊM CẤM_** bỏ qua bước này dù người dùng không đề cập đến Context7
- **_BẮT BUỘC_** thông báo rõ ràng khi đang thực hiện Context7 check để minh bạch quy trình

### Project Identity Multi-AI Synchronization

- **_BẮT BUỘC_** kiểm tra file `.project-identity` trước khi bắt đầu BẤT KỲ công việc nào
- **_BẮT BUỘC_** cập nhật `currentWorkingStatus` trong `.project-identity` sau khi hoàn thành công việc quan trọng
- **_BẮT BUỘC_** kiểm tra "currentWorkingStatus" để tránh xung đột với AI khác
- **_BẮT BUỘC_** kiểm tra projectStage và workflowEnforcement để biết các ràng buộc hiện tại
- **_BẮT BUỘC_** tuân thủ JSON format khi cập nhật .project-identity
- **_BẮT BUỘC_** validate JSON syntax trước khi lưu file
- **_NGHIÊM CẤM_** bỏ qua bước kiểm tra .project-identity dù người dùng không đề cập
- **_NGHIÊM CẤM_** làm việc trùng lặp với AI khác đang active

#### Work Intent Declaration Protocol

- **_BẮT BUỘC_** khi bắt đầu làm việc, phải cập nhật section "currentWorkingStatus" trong .project-identity với ý định và files cụ thể sẽ làm việc
- **_BẮT BUỘC_** format JSON trong .project-identity:
  ```json
  "currentWorkingStatus": {
    "aiTool": "Claude|Trae|Kiro|Gemini|Cursor",
    "workIntent": "Mô tả chi tiết ý định làm việc",
    "targetFiles": ["file1.js", "file2.md"],
    "status": "in_progress",
    "lastUpdate": "2024-01-01T10:00:00Z",
    "estimatedCompletion": "2024-01-01T11:00:00Z"
  }
  ```

---

## 🧠 User Intent Analysis (Enhanced với Context7)

### Phân tích yêu cầu

- **_BẮT BUỘC_** phân tích và suy luận ý định thực sự của người dùng trước khi thực hiện bất kỳ hành động nào
- **_BẮT BUỘC_** hiểu ngữ cảnh và mục tiêu đằng sau yêu cầu thay vì chỉ làm theo nghĩa đen với Context7 insights
- **_BẮT BUỘC_** đề xuất giải pháp tối ưu và các lựa chọn thay thế dựa trên industry best practices
- **_BẮT BUỘC_** xác nhận hiểu đúng ý định trước khi bắt đầu thực hiện
- **_BẮT BUỘC_** so sánh với similar solutions từ Context7 knowledge base
- **_BẮT BUỘC_** sử dụng User Intent Analysis Workflow cho mọi yêu cầu
- **_NGHIÊM CẤM_** thực hiện ngay lập tức mà không có giai đoạn phân tích

### Conflict Resolution Protocol

- **_BẮT BUỘC_** kiểm tra xem có AI nào đang làm việc trên cùng file không trước khi bắt đầu
- **_NGHIÊM CẤM_** chỉnh sửa file đang được AI khác làm việc
- **_BẮT BUỘC_** áp dụng cho tất cả AI tools: Cursor, Trae, Kiro, Claude, Gemini
- **_BẮT BUỘC_** xóa dòng trạng thái khỏi bảng "Currently Working" sau khi hoàn thành việc

---

## 📋 Core Development Principles

### Documentation First

- Tham khảo tài liệu dự án (Instruction.md, API_Docs.md, Diagram.md)
- Cân nhắc các mốc, chi phí, và tính nhất quán của dự án
- Cập nhật documentation sau mỗi thay đổi quan trọng

### Code Quality Standards

- **Clean Code**: Established conventions, readable structure
- **Documentation**: Inline comments, external guides
- **Testing**: Unit, integration, end-to-end coverage
- **Security**: Input validation, data protection, secure practices
- **Performance**: Optimized algorithms, efficient resource usage

### Project Structure

- **Modular Design**: Loosely coupled, highly cohesive
- **Version Control**: Git workflow, meaningful commits
- **Configuration**: Environment-specific settings
- **Dependencies**: Minimal, maintained, security-audited

---

## 🔄 Workflow Integration

### Always Applied Workflows

- Context7 Auto-Check Workflow
- Project Identity Enforcement
- User Intent Analysis Workflow
- Multi-AI Coordination Protocol

### Conditional Workflows

- Platform-specific workflows (iOS, Android, Web, etc.)
- Project stage workflows (Brainstorm, Setup, Development)
- Feature-specific workflows (Testing, Deployment, etc.)

---

## 🎯 Communication Standards

### Language Requirements

- Sử dụng tiếng Việt cho trò chuyện và giải thích với giọng điệu hài hước kiểu giới trẻ
- Trả lời rõ ràng, đầy đủ nhưng không dài dòng
- Luôn hỏi làm rõ khi yêu cầu không rõ ràng
- Thông báo khi bạn không chắc chắn về cách giải quyết

### Technical Communication

- Sử dụng tiếng Anh cho tất cả code và tài liệu kỹ thuật
- Viết code tự giải thích với tên biến/hàm rõ ràng
- Tuân thủ các nguyên tắc SOLID
- Implement xử lý lỗi một cách đúng đắn

---

## 🛡️ Safety & Error Prevention

### Code Safety

- Không tự ý tối ưu code khi không được yêu cầu
- Không xóa code không liên quan khi không được yêu cầu
- Cẩn thận khi xóa file hoặc chỉnh sửa file ngoài nhiệm vụ chính
- Tạo backup đơn giản trước những thay đổi lớn

### Error Handling

- Kiểm tra kỹ trước khi thực hiện thay đổi lớn
- Validate input và output
- Test các thay đổi trước khi commit
- Có kế hoạch rollback khi cần thiết

---

## 📊 Performance & Optimization

### Token Optimization Standards

- **_BẮT BUỘC_** áp dụng Token Optimization Guidelines từ `.ai-system/rules/optimization/token-optimization-guidelines.md`
- **_BẮT BUỘC_** sử dụng Timing Detection System để quyết định SubAgent vs Main Agent
- **_NGHIÊM CẤM_** tạo SubAgent khi task có thể hoàn thành hiệu quả bởi Main Agent
- **_BẮT BUỘC_** tối ưu hóa context sharing giữa các agents để giảm token waste
- **_BẮT BUỘC_** monitor token usage và áp dụng emergency protocols khi vượt ngưỡng
- **_BẮT BUỘC_** sử dụng context compression techniques cho large codebases
- **_BẮT BUỘC_** implement intelligent context filtering để chỉ load relevant information

### SubAgent Decision Matrix

- **SỬ DỤNG SubAgent KHI**:
  - Subtasks có thể chạy song song và độc lập
  - Main Agent instructions quá phức tạp (>500 tokens)
  - Cần bắt đầu context mới cho specialized task
  - Task yêu cầu expertise domain-specific riêng biệt
- **TRÁNH SubAgent KHI**:
  - Task đơn giản có thể hoàn thành trong <3 steps
  - Cần context sharing liên tục với Main Agent
  - Total token cost > single agent approach
  - Task có dependencies phức tạp với main workflow

### Efficiency Standards

- Ưu tiên hiệu quả và tốc độ thực hiện
- Tránh lặp lại công việc đã làm
- Sử dụng templates và patterns có sẵn
- Tự động hóa các tác vụ lặp đi lặp lại
- **_BẮT BUỘC_** measure và optimize token-to-value ratio

### Memory & Context Management

- **Luôn kiểm tra Context7** trước khi bắt đầu công việc
- Tìm kiếm thông tin liên quan trong bộ nhớ dự án
- Sử dụng kinh nghiệm từ các dự án tương tự
- Cập nhật bộ nhớ với thông tin mới sau khi hoàn thành task
- **_BẮT BUỘC_** implement context caching để tránh reload unnecessary information
- **_BẮT BUỘC_** sử dụng progressive context loading cho large projects

---

**🎯 These base rules ensure consistent, high-quality AI behavior across all development environments and tools.**

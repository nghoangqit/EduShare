class SupportBotService {
  const SupportBotService();

  String replyFor(String message) {
    final text = _normalize(message);

    if (_hasAny(text, ['don hang', 'dat hang', 'mua hang', 'trang thai'])) {
      return 'Mình là EduShare AI. Bạn có thể vào Hồ sơ > Lịch sử mua hàng để xem trạng thái đơn. Nếu đơn đang chờ xác nhận, hãy kiểm tra phương thức thanh toán và nội dung chuyển khoản. Nếu cần admin kiểm tra riêng, bạn gửi mã đơn hàng tại đây nhé.';
    }

    if (_hasAny(text, ['thanh toan', 'chuyen khoan', 'cod', 'tra tien'])) {
      return 'Về thanh toán, EduShare hỗ trợ ví EduShare, chuyển khoản và thanh toán khi nhận hàng. Nếu chuyển khoản, bạn cần dùng đúng nội dung giao dịch trong đơn để admin đối soát nhanh hơn.';
    }

    if (_hasAny(text, ['vi', 'nap tien', 'rut tien', 'so du', 'payout'])) {
      return 'Về ví EduShare: bạn có thể nạp tiền trong Hồ sơ. Sau khi admin xác nhận, số dư sẽ được cộng vào ví. Tiền bán hàng sẽ được giải ngân sau khi đơn được xác nhận giao thành công theo tỷ lệ hiện hành của EduShare.';
    }

    if (_hasAny(text, ['giao hang', 'nhan hang', 'dia chi', 'ship'])) {
      return 'Khi đặt hàng, bạn hãy xác nhận tên, số điện thoại, địa chỉ và vị trí trên bản đồ. Vị trí bản đồ giúp người bán giao đúng điểm hơn, còn địa chỉ chữ giúp đối chiếu khi cần liên hệ.';
    }

    if (_hasAny(text, ['ban do', 'map', 'dinh vi', 'vi tri', 'gps'])) {
      return 'Để chọn vị trí giao hàng, bấm Chọn vị trí trên bản đồ trong bước xác nhận địa chỉ. Bạn có thể tìm địa điểm, chạm trên bản đồ hoặc bấm nút định vị để lấy vị trí hiện tại.';
    }

    if (_hasAny(text, ['thong bao', 'notification', 'bao loi thong bao'])) {
      return 'Nếu không thấy thông báo nổi trên điện thoại, hãy cấp quyền thông báo cho EduShare trong cài đặt máy. Khi app đang chạy, EduShare sẽ hiện popup cho tin nhắn và cập nhật mới.';
    }

    if (_hasAny(text, ['dang ban', 'ban sach', 'them san pham', 'san pham'])) {
      return 'Để đăng bán, bấm nút + ở thanh điều hướng, nhập thông tin sản phẩm, giá, tồn kho và ảnh. Nên đặt tiêu đề rõ, ghi đúng trường và tình trạng để người mua tìm thấy nhanh hơn.';
    }

    if (_hasAny(text, ['tai khoan', 'dang nhap', 'mat khau', 'ho so'])) {
      return 'Về tài khoản, hãy kiểm tra Hồ sơ để cập nhật tên, số điện thoại, trường và địa chỉ nhận hàng. Nếu gặp lỗi đăng nhập hoặc bị khóa tài khoản, bạn gửi email tài khoản để admin kiểm tra.';
    }

    if (_hasAny(text, ['loi', 'bug', 'khong duoc', 'khong mo', 'treo'])) {
      return 'Mình ghi nhận là bạn đang gặp lỗi. Bạn gửi giúp mình: màn hình đang lỗi, thao tác trước khi lỗi xảy ra, và ảnh chụp màn hình nếu có. Admin sẽ có đủ thông tin để xử lý nhanh hơn.';
    }

    if (_hasAny(text, ['cam on', 'thanks', 'thank'])) {
      return 'Rất vui được hỗ trợ bạn. Nếu còn vấn đề nào khác, cứ nhắn tiếp tại đây nhé.';
    }

    return 'Mình là EduShare AI, có thể hỗ trợ nhanh về đơn hàng, thanh toán, ví EduShare, giao hàng, bản đồ, thông báo, tài khoản và đăng bán sản phẩm. Bạn mô tả vấn đề cụ thể hơn để mình hướng dẫn đúng hơn nhé.';
  }

  bool _hasAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  String _normalize(String value) {
    var text = value.trim().toLowerCase();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text;
  }
}

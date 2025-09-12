import 'package:flutter/material.dart';
// TODO: Đảm bảo đường dẫn này chính xác đến file service của bạn
import '../../services/odoo_api_service.dart';
// TODO: Đảm bảo bạn có file này hoặc thay thế bằng màn hình chính của bạn
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key để quản lý và kiểm tra trạng thái của Form
  final _formKey = GlobalKey<FormState>();

  // Service để giao tiếp với Odoo API
  final OdooApiService _apiService = OdooApiService();

  // Controllers để lấy dữ liệu từ các ô TextFormField
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Biến quản lý trạng thái loading
  bool _isLoading = false;

  // Biến để quản lý việc ẩn/hiện mật khẩu
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Dọn dẹp controllers khi widget bị hủy để tránh rò rỉ bộ nhớ
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý logic đăng nhập khi người dùng nhấn nút
  Future<void> _login() async {
    // 1. Kiểm tra xem form có hợp lệ không (các trường đã được điền đúng chưa)
    if (!_formKey.currentState!.validate()) {
      return; // Nếu không hợp lệ, dừng lại
    }

    // 2. Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // 3. Cập nhật UI để hiển thị vòng xoay loading
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Gọi hàm login từ service
      // Dùng .trim() để xóa các khoảng trắng thừa ở đầu và cuối chuỗi
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 5. Nếu không có lỗi, điều hướng đến màn hình chính
      // pushReplacement ngăn người dùng quay lại màn hình đăng nhập sau khi đã đăng nhập thành công
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } on Exception catch (e) {
      // 6. Nếu có lỗi, bắt Exception và hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      // 7. Dù thành công hay thất bại, cuối cùng cũng phải ẩn vòng xoay loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Logo hoặc Tên Ứng Dụng ---
                  Icon(
                    Icons.fact_check_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SGCGO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Ô nhập Email ---
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email hoặc Tên đăng nhập',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Ô nhập Mật khẩu ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Ẩn/hiện mật khẩu
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- Nút Đăng nhập ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

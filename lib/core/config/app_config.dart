/// 联调默认指向 Cloudflare workers.dev，可用 --dart-define 覆盖。
class AppConfig {
  static const workersBaseUrl = String.fromEnvironment(
    'WORKERS_BASE_URL',
    defaultValue: 'https://digiplayers-workers.wasai-test.workers.dev',
  );
}

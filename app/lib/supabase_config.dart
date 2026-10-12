/// Project URL и publishable-ключ из Supabase → Project Settings → API.
/// Ключ публичный, его можно коммитить; secret / service_role сюда класть нельзя.
/// Пока ключ пустой, входа нет и приложение живёт только на устройстве.
const supabaseUrl = 'https://ynwpzcoayepczgtayimr.supabase.co';
const supabaseKey = 'sb_publishable_zCKHGcJCVSQ71FiQYZS1jA_DPNoaapt';

/// Письмо приходит с кодом, а не со ссылкой. На встроенной почте Supabase шаблон письма не меняется,
/// поэтому включать только вместе со своим SMTP и `{{ .Token }}` в шаблонах Magic Link и Confirm signup.
const kEmailCode = false;

/// Сюда возвращает ссылка из письма; адрес должен быть в Authentication → URL Configuration → Redirect URLs.
const authRedirect = 'kapiras://login-callback';

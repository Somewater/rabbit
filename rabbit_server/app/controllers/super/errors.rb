# нет указанного метода-обработчика
class MethodError < RuntimeError;
end

# базовая авторизация не пройдена (в т.ч. получение данных о пользователе)
class AuthError < RuntimeError;
end

# данные запроса имеют неизвестный формат
class FormatError < RuntimeError;
end

# произошло обращение к методу, требующему переопределение
class UnimplementedError < RuntimeError;
end
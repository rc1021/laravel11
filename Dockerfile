# 使用 Ubuntu 24.04 作為基礎鏡像
FROM ubuntu:24.04

# 設置環境變數
ENV DEBIAN_FRONTEND=noninteractive


# 更新系統並安裝必要工具
RUN apt update && apt upgrade -y && \
    apt install -y software-properties-common curl wget unzip git nginx supervisor lsb-release && \
    add-apt-repository ppa:ondrej/php -y && \
    apt update

# 安裝 PHP 和相關擴展
RUN apt install -y php php-cli php-fpm php8.3-redis php-mysql php-zip php-mbstring php-curl php-xml php-bcmath php-tokenizer php-common && \
    php -m | grep -E 'ctype|curl|dom|fileinfo|filter|hash|mbstring|openssl|pcre|pdo|session|tokenizer|xml'

# 安裝 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer --version

# 安裝 Node.js 和 NPM（可選，適用於 Laravel Mix）
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt install -y nodejs

# 設置工作目錄
WORKDIR /var/www/html

# # 複製代碼到容器中
# COPY . /var/www/html

# # 運行 Composer 安裝 Laravel 依賴
# RUN composer install --optimize-autoloader --no-interaction

# # 設置檔案權限
# RUN chown -R www-data:www-data /var/www/html && \
#     chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 配置 Supervisor，啟動 Laravel Worker
COPY supervisord/supervisord.conf /etc/supervisord.conf
COPY supervisord/conf.d/laravel-worker.conf /etc/supervisor/conf.d/laravel-worker.conf

# 配置 Nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/sites/default.conf /etc/nginx/sites-available/default.conf

COPY ./crontab /etc/cron.d
RUN chmod -R 644 /etc/cron.d

CMD ["supervisord", "-c", "/etc/supervisord.conf"]

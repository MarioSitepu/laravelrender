FROM php:8.3-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip

# Install Composer v2
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Buat folder aplikasi
RUN mkdir -p /var/www/html

# Set working directory
WORKDIR /var/www/html

# Copy SELURUH aplikasi (termasuk file artisan)
COPY . .

# Install dependencies (skip platform reqs dan post-scripts)
RUN composer install --no-dev --no-interaction --optimize-autoloader --ignore-platform-reqs --no-scripts

# Set permission
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Jalankan post-install commands manual
RUN composer run-script post-autoload-dump

# Expose port 9000
EXPOSE 9000

CMD ["php-fpm"]
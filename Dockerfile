# ==============================================
# STAGE 1: BUILD COMPOSER DEPENDENCIES
# ==============================================
FROM composer:2.6 AS builder
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --optimize-autoloader \
    --no-scripts

# ==============================================
# STAGE 2: PRODUCTION RUNTIME (PHP 8.3)
# ==============================================
FROM php:8.3-apache
WORKDIR /var/www/html

# Copy application files
COPY --from=builder /app/vendor ./vendor
COPY . .

# Apache configuration
COPY .docker/apache.conf /etc/apache2/sites-available/000-default.conf

# Install system dependencies
RUN apt-get update -y && \
    apt-get install -y \
    libpq-dev \
    libzip-dev \
    zip \
    unzip && \
    docker-php-ext-install pdo pdo_pgsql zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set permissions
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Configure Apache
RUN a2enmod rewrite && \
    a2enmod headers && \
    service apache2 restart

# Run Laravel optimization
RUN php artisan config:clear && \
    php artisan view:clear && \
    php artisan route:clear && \
    php artisan optimize

EXPOSE 80
CMD ["apache2-foreground"]
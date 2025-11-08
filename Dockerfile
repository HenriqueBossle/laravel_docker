# Etapa 1: Imagem base do PHP com Apache
FROM php:8.3-apache

# Instalar dependências do sistema e extensões necessárias do Laravel
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libjpeg-dev libfreetype6-dev zip unzip libonig-dev libxml2-dev libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd

# Habilitar mod_rewrite do Apache (necessário para Laravel)
RUN a2enmod rewrite

# Copiar os arquivos da aplicação para dentro do container
COPY . /var/www/html

# Definir o diretório de trabalho
WORKDIR /var/www/html

# Instalar o Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Instalar dependências do Laravel
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Definir variáveis do Apache
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80

# Rodar migrations automaticamente no deploy
RUN php artisan migrate --force || true


CMD ["apache2-foreground"]

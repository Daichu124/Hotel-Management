-- 1. Tạo Database (nếu chưa có)
CREATE DATABASE IF NOT EXISTS hotel_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hotel_management;

-- 2. Xóa bảng cũ theo thứ tự ngược để tránh lỗi khóa ngoại (Foreign Key)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS booking_services;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- BẮT ĐẦU TẠO BẢNG
-- ============================================================

-- Bảng người dùng (Nhân viên)
CREATE TABLE users (
                       id              INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                       username        VARCHAR(50) UNIQUE NOT NULL,
                       password_hash   VARCHAR(255) NOT NULL,
                       full_name       VARCHAR(100) NOT NULL,
                       phone           VARCHAR(20),
                       role            ENUM('admin', 'manager', 'receptionist', 'staff') NOT NULL DEFAULT 'receptionist',
                       is_active       BOOLEAN NOT NULL DEFAULT true,
                       created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Bảng khách hàng
CREATE TABLE customers (
                           id          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                           full_name   VARCHAR(100) NOT NULL,
                           id_number   VARCHAR(20) UNIQUE,
                           phone       VARCHAR(20),
                           email       VARCHAR(100),
                           address     VARCHAR(255),
                           created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Tối ưu tìm kiếm khách hàng bằng SDT hoặc CMND
                           INDEX idx_customer_phone (phone),
                           INDEX idx_customer_id_number (id_number)
) ENGINE=InnoDB;

-- Bảng phòng
CREATE TABLE rooms (
                       id                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                       room_number         VARCHAR(10) UNIQUE NOT NULL,
                       room_type           ENUM('single', 'double', 'twin', 'vip', 'suite') NOT NULL DEFAULT 'single',
                       floor               INT NOT NULL DEFAULT 1,
                       price_per_day       DECIMAL(12,2) NOT NULL,
                       price_first_hour    DECIMAL(12,2) NOT NULL,
                       price_next_hour     DECIMAL(12,2) NOT NULL,
                       status              ENUM('available', 'occupied', 'cleaning', 'maintenance', 'reserved') NOT NULL DEFAULT 'available',
                       max_occupancy       TINYINT NOT NULL DEFAULT 2,
                       description         TEXT,

    -- Tối ưu việc lọc phòng trống/loại phòng
                       INDEX idx_room_status (status),
                       INDEX idx_room_type (room_type)
) ENGINE=InnoDB;

-- Bảng dịch vụ
CREATE TABLE services (
                          id          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                          name        VARCHAR(150) NOT NULL,
                          price       DECIMAL(12,2) NOT NULL,
                          unit        VARCHAR(50) DEFAULT 'phần',
                          is_active   BOOLEAN NOT NULL DEFAULT true,
                          description TEXT
) ENGINE=InnoDB;

-- Bảng đặt phòng
CREATE TABLE bookings (
                          id                        INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                          customer_id               INT UNSIGNED NOT NULL,
                          room_id                   INT UNSIGNED NOT NULL,
                          employee_id               INT UNSIGNED,
                          rent_type                 ENUM('hourly', 'daily', 'overnight') NOT NULL DEFAULT 'daily',
                          planned_check_in          DATETIME,
                          planned_check_out         DATETIME,
                          actual_check_in           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          actual_check_out          DATETIME,
                          status                    ENUM('confirmed', 'checked_in', 'checked_out', 'cancelled') NOT NULL DEFAULT 'checked_in',
                          locked_price_day          DECIMAL(12,2) NOT NULL,
                          locked_price_first_hour   DECIMAL(12,2) NOT NULL,
                          locked_price_next_hour    DECIMAL(12,2) NOT NULL,
                          deposit                   DECIMAL(12,2) NOT NULL DEFAULT 0,
                          notes                     TEXT,

                          CONSTRAINT fk_bk_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
                          CONSTRAINT fk_bk_room FOREIGN KEY (room_id) REFERENCES rooms(id),
                          CONSTRAINT fk_bk_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE SET NULL,

    -- Tối ưu tìm kiếm booking theo trạng thái và thời gian check-in/out
                          INDEX idx_booking_status (status),
                          INDEX idx_booking_dates (actual_check_in, actual_check_out)
) ENGINE=InnoDB;

-- Bảng dịch vụ đi kèm khi đặt phòng
CREATE TABLE booking_services (
                                  id            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                                  booking_id    INT UNSIGNED NOT NULL,
                                  service_id    INT UNSIGNED NOT NULL,
                                  quantity      SMALLINT NOT NULL DEFAULT 1,
                                  unit_price    DECIMAL(12,2) NOT NULL,
                                  used_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  employee_id   INT UNSIGNED,

                                  CONSTRAINT fk_bs_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
                                  CONSTRAINT fk_bs_service FOREIGN KEY (service_id) REFERENCES services(id),
                                  CONSTRAINT fk_bs_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Bảng hóa đơn thanh toán
CREATE TABLE invoices (
                          id                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
                          invoice_no        VARCHAR(20) UNIQUE NOT NULL,
                          booking_id        INT UNSIGNED UNIQUE NOT NULL,
                          employee_id       INT UNSIGNED,
                          room_total        DECIMAL(12,2) NOT NULL DEFAULT 0,
                          service_total     DECIMAL(12,2) NOT NULL DEFAULT 0,
                          discount          DECIMAL(12,2) NOT NULL DEFAULT 0,
                          deposit_used      DECIMAL(12,2) NOT NULL DEFAULT 0,
                          grand_total       DECIMAL(12,2) NOT NULL DEFAULT 0,
                          payment_method    ENUM('cash', 'card', 'transfer', 'mixed') NOT NULL DEFAULT 'cash',
                          payment_note      TEXT,
                          created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

                          CONSTRAINT fk_inv_booking FOREIGN KEY (booking_id) REFERENCES bookings(id),
                          CONSTRAINT fk_inv_employee FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
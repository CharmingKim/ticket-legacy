-- =============================================================================
--  TicketLegacy TOTAL SCHEMA (Verified Gold Master Version - Rev.3)
--  珥45媛뚯씠釉꾩닔 ы븿 (쒓 몄퐫꾨꼍 蹂듦뎄)
-- =============================================================================

DROP DATABASE IF EXISTS springgreen6;
CREATE DATABASE springgreen6 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE springgreen6;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- [1] accessible_seat
CREATE TABLE `accessible_seat` (
  `accessible_id` bigint NOT NULL AUTO_INCREMENT,
  `seat_id` bigint NOT NULL,
  `accessible_type` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `companion_count` tinyint DEFAULT '1',
  `note` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`accessible_id`),
  UNIQUE KEY `seat_id` (`seat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [2] admin_action_log
CREATE TABLE `admin_action_log` (
  `log_id` bigint NOT NULL AUTO_INCREMENT,
  `admin_member_id` bigint NOT NULL,
  `action_type` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_id` bigint DEFAULT NULL,
  `before_value` text COLLATE utf8mb4_unicode_ci,
  `after_value` text COLLATE utf8mb4_unicode_ci,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_aal_admin` (`admin_member_id`),
  KEY `idx_aal_created` (`created_at`),
  KEY `idx_aal_target` (`target_type`,`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [3] daily_stats
CREATE TABLE `daily_stats` (
  `stats_date` date NOT NULL,
  `new_members` int DEFAULT '0',
  `active_members` int DEFAULT '0',
  `total_reservations` int DEFAULT '0',
  `confirmed_reservations` int DEFAULT '0',
  `cancelled_reservations` int DEFAULT '0',
  `total_sales` bigint DEFAULT '0',
  `total_refunds` bigint DEFAULT '0',
  `new_performances` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`stats_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [4] faq
CREATE TABLE `faq` (
  `faq_id` bigint NOT NULL AUTO_INCREMENT,
  `category` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `question` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `answer` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `sort_order` int NOT NULL DEFAULT '0',
  `display_order` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `author_member_id` bigint DEFAULT NULL,
  `view_count` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`faq_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [5] member
CREATE TABLE `member` (
  `member_id` bigint NOT NULL AUTO_INCREMENT,
  `email` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'USER' COMMENT 'USER | SUPER_ADMIN | STAFF | PROMOTER | VENUE_MANAGER',
  `status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE | DORMANT | WITHDRAWN | PENDING_APPROVAL',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login_at` datetime DEFAULT NULL,
  PRIMARY KEY (`member_id`),
  UNIQUE KEY `uk_member_email` (`email`),
  KEY `idx_member_role_status` (`role`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [6] member_sanction
CREATE TABLE `member_sanction` (
  `sanction_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `sanction_type` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sanctioned_by` bigint NOT NULL,
  `sanctioned_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `lifted_at` datetime DEFAULT NULL,
  `lifted_by` bigint DEFAULT NULL,
  `lift_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`sanction_id`),
  KEY `idx_ms_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [7] member_status_history
CREATE TABLE `member_status_history` (
  `history_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `from_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `to_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `changed_by` bigint DEFAULT NULL,
  `reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`history_id`),
  KEY `idx_msh_member` (`member_id`),
  KEY `idx_msh_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [8] member_terms_agreement
CREATE TABLE `member_terms_agreement` (
  `agreement_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `terms_id` bigint NOT NULL,
  `agreed` tinyint(1) NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `agreed_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`agreement_id`),
  UNIQUE KEY `uk_mta_member_terms` (`member_id`,`terms_id`),
  KEY `idx_mta_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [9] notification
CREATE TABLE `notification` (
  `notification_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `template_id` bigint DEFAULT NULL,
  `channel` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `related_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `related_id` bigint DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `sent_at` datetime DEFAULT NULL,
  `read_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `idx_notif_member` (`member_id`),
  KEY `idx_notif_unread` (`member_id`,`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [10] notification_template
CREATE TABLE `notification_template` (
  `template_id` bigint NOT NULL AUTO_INCREMENT,
  `template_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `channel` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title_template` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body_template` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`template_id`),
  UNIQUE KEY `template_code` (`template_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [11] performance_review
CREATE TABLE `performance_review` (
  `review_id` bigint NOT NULL AUTO_INCREMENT,
  `performance_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `reservation_id` bigint NOT NULL,
  `rating` tinyint NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci,
  `is_visible` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uk_review_member_perf` (`member_id`,`performance_id`),
  KEY `idx_review_performance` (`performance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [12] performance_stats
CREATE TABLE `performance_stats` (
  `performance_id` bigint NOT NULL,
  `total_seats` int DEFAULT '0',
  `sold_seats` int DEFAULT '0',
  `reserved_seats` int DEFAULT '0',
  `cancelled_seats` int DEFAULT '0',
  `total_revenue` bigint DEFAULT '0',
  `avg_rating` decimal(3,2) DEFAULT '0.00',
  `review_count` int DEFAULT '0',
  `view_count` int DEFAULT '0',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`performance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [13] point_balance
CREATE TABLE `point_balance` (
  `balance_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `total_earned` int NOT NULL DEFAULT '0',
  `total_used` int NOT NULL DEFAULT '0',
  `available_point` int NOT NULL DEFAULT '0',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`balance_id`),
  UNIQUE KEY `member_id` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [14] point_history
CREATE TABLE `point_history` (
  `history_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `point_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` int NOT NULL,
  `balance_after` int NOT NULL,
  `related_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `related_id` bigint DEFAULT NULL,
  `description` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`history_id`),
  KEY `idx_ph_member` (`member_id`),
  KEY `idx_ph_created` (`created_at`),
  KEY `idx_ph_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [15] queue_token
CREATE TABLE `queue_token` (
  `token_id` bigint NOT NULL AUTO_INCREMENT,
  `token_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `member_id` bigint NOT NULL,
  `performance_id` bigint NOT NULL,
  `queue_position` int DEFAULT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'WAITING',
  `issued_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `expires_at` datetime DEFAULT NULL,
  `activated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token_key` (`token_key`),
  KEY `idx_qt_member_perf` (`member_id`,`performance_id`),
  KEY `idx_qt_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [16] refund
CREATE TABLE `refund` (
  `refund_id` bigint NOT NULL AUTO_INCREMENT,
  `payment_id` bigint NOT NULL,
  `reservation_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `refund_amount` int NOT NULL,
  `refund_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `refund_type` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `processed_by` bigint DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `pg_refund_id` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`refund_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [17] refund_policy
CREATE TABLE `refund_policy` (
  `policy_id` bigint NOT NULL AUTO_INCREMENT,
  `performance_id` bigint DEFAULT NULL,
  `days_before_show` int NOT NULL,
  `refund_rate` tinyint NOT NULL,
  `description` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`policy_id`),
  KEY `idx_rp_performance` (`performance_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [18] review_report
CREATE TABLE `review_report` (
  `report_id` bigint NOT NULL AUTO_INCREMENT,
  `review_id` bigint NOT NULL,
  `reporter_id` bigint NOT NULL,
  `reason` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `detail` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `processed_by` bigint DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`report_id`),
  KEY `idx_rr_review` (`review_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [19] search_keyword_log
CREATE TABLE `search_keyword_log` (
  `log_id` bigint NOT NULL AUTO_INCREMENT,
  `keyword` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `member_id` bigint DEFAULT NULL,
  `result_count` int DEFAULT NULL,
  `searched_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_skl_keyword` (`keyword`),
  KEY `idx_skl_searched` (`searched_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [20] settlement
CREATE TABLE `settlement` (
  `settlement_id` bigint NOT NULL AUTO_INCREMENT,
  `promoter_id` bigint NOT NULL,
  `settlement_month` varchar(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_sales` bigint NOT NULL DEFAULT '0',
  `platform_fee` int NOT NULL DEFAULT '0',
  `vat` int NOT NULL DEFAULT '0',
  `net_amount` bigint NOT NULL DEFAULT '0',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `confirmed_by` bigint DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `note` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`settlement_id`),
  UNIQUE KEY `uk_settlement_promoter_month` (`promoter_id`,`settlement_month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [21] settlement_item
CREATE TABLE `settlement_item` (
  `item_id` bigint NOT NULL AUTO_INCREMENT,
  `settlement_id` bigint NOT NULL,
  `performance_id` bigint NOT NULL,
  `performance_title` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sold_count` int NOT NULL DEFAULT '0',
  `refund_count` int NOT NULL DEFAULT '0',
  `gross_amount` bigint NOT NULL DEFAULT '0',
  `refund_amount` bigint NOT NULL DEFAULT '0',
  `net_amount` bigint NOT NULL DEFAULT '0',
  PRIMARY KEY (`item_id`),
  KEY `idx_si_settlement` (`settlement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [22] terms
CREATE TABLE `terms` (
  `terms_id` bigint NOT NULL AUTO_INCREMENT,
  `terms_type` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `version` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_required` tinyint(1) DEFAULT '1',
  `effective_at` datetime NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`terms_id`),
  UNIQUE KEY `uk_terms_type_ver` (`terms_type`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [23] venue
CREATE TABLE `venue` (
  `venue_id` bigint NOT NULL AUTO_INCREMENT,
  `api_facility_id` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `seat_scale` int DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`venue_id`),
  UNIQUE KEY `uk_venue_api` (`api_facility_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [24] inquiry
CREATE TABLE `inquiry` (
  `inquiry_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`inquiry_id`),
  CONSTRAINT `fk_inq_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [25] notice
CREATE TABLE `notice` (
  `notice_id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `notice_type` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SYSTEM',
  `target_role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ALL',
  `is_pinned` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `author_member_id` bigint NOT NULL,
  `view_count` int NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`notice_id`),
  CONSTRAINT `fk_notice_author` FOREIGN KEY (`author_member_id`) REFERENCES `member` (`member_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [26] promoter
CREATE TABLE `promoter` (
  `promoter_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `company_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `business_reg_no` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `representative` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_email` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contract_doc_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approval_status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approved_by` bigint DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `reject_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`promoter_id`),
  UNIQUE KEY `uk_promoter_member` (`member_id`),
  UNIQUE KEY `uk_promoter_brn` (`business_reg_no`),
  CONSTRAINT `fk_promoter_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [27] venue_manager
CREATE TABLE `venue_manager` (
  `manager_id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `venue_id` bigint NOT NULL,
  `department` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `position` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approval_status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approved_by` bigint DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`manager_id`),
  UNIQUE KEY `uk_vm_member` (`member_id`),
  CONSTRAINT `fk_vm_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_vm_venue` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`venue_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [28] venue_section
CREATE TABLE `venue_section` (
  `section_id` bigint NOT NULL AUTO_INCREMENT,
  `venue_id` bigint NOT NULL,
  `section_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `section_type` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_rows` int NOT NULL,
  `seats_per_row` int NOT NULL,
  `display_order` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`section_id`),
  CONSTRAINT `fk_vs_venue` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`venue_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [29] venue_stage_config
CREATE TABLE `venue_stage_config` (
  `config_id` bigint NOT NULL AUTO_INCREMENT,
  `venue_id` bigint NOT NULL,
  `config_name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`config_id`),
  CONSTRAINT `fk_vsc_venue` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`venue_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [30] venue_stage_section
CREATE TABLE `venue_stage_section` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `config_id` bigint NOT NULL,
  `section_id` bigint NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `custom_rows` int DEFAULT NULL,
  `custom_seats_per_row` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_vss_pair` (`config_id`,`section_id`),
  CONSTRAINT `fk_vss_config` FOREIGN KEY (`config_id`) REFERENCES `venue_stage_config` (`config_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_vss_section` FOREIGN KEY (`section_id`) REFERENCES `venue_section` (`section_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [31] performance
CREATE TABLE `performance` (
  `performance_id` bigint NOT NULL AUTO_INCREMENT,
  `api_perf_id` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CONCERT',
  `age_limit` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `running_time` int DEFAULT NULL,
  `min_price` int DEFAULT NULL,
  `venue_id` bigint NOT NULL,
  `venue_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `poster_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_seats` int NOT NULL DEFAULT '0',
  `ticket_open_at` datetime DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'UPCOMING',
  `stage_config_id` bigint DEFAULT NULL,
  `promoter_id` bigint DEFAULT NULL,
  `approval_status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `approval_note` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reviewed_by` bigint DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`performance_id`),
  UNIQUE KEY `uk_perf_api` (`api_perf_id`),
  CONSTRAINT `fk_perf_promoter` FOREIGN KEY (`promoter_id`) REFERENCES `promoter` (`promoter_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_perf_venue` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`venue_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [32] performance_seat_grade
CREATE TABLE `performance_seat_grade` (
  `grade_id` bigint NOT NULL AUTO_INCREMENT,
  `performance_id` bigint NOT NULL,
  `section_id` bigint NOT NULL,
  `grade` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `price` int NOT NULL,
  PRIMARY KEY (`grade_id`),
  UNIQUE KEY `uk_psg_pair` (`performance_id`,`section_id`),
  CONSTRAINT `fk_psg_perf` FOREIGN KEY (`performance_id`) REFERENCES `performance` (`performance_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_psg_section` FOREIGN KEY (`section_id`) REFERENCES `venue_section` (`section_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [33] performance_section_override
CREATE TABLE `performance_section_override` (
  `override_id` bigint NOT NULL AUTO_INCREMENT,
  `performance_id` bigint NOT NULL,
  `section_id` bigint NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `custom_rows` int DEFAULT NULL,
  `custom_seats_per_row` int DEFAULT NULL,
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`override_id`),
  UNIQUE KEY `uk_pso_pair` (`performance_id`,`section_id`),
  CONSTRAINT `fk_pso_perf` FOREIGN KEY (`performance_id`) REFERENCES `performance` (`performance_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pso_section` FOREIGN KEY (`section_id`) REFERENCES `venue_section` (`section_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [34] performance_wishlist
CREATE TABLE `performance_wishlist` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `performance_id` bigint NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wish` (`member_id`,`performance_id`),
  CONSTRAINT `fk_wish_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wish_perf` FOREIGN KEY (`performance_id`) REFERENCES `performance` (`performance_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [35] schedule
CREATE TABLE `schedule` (
  `schedule_id` bigint NOT NULL AUTO_INCREMENT,
  `performance_id` bigint NOT NULL,
  `show_date` date NOT NULL,
  `show_time` time NOT NULL,
  `available_seats` int NOT NULL DEFAULT '0',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AVAILABLE',
  `max_seats_per_order` int NOT NULL DEFAULT '4',
  PRIMARY KEY (`schedule_id`),
  UNIQUE KEY `uk_schedule_pdt` (`performance_id`,`show_date`,`show_time`),
  CONSTRAINT `fk_schedule_perf` FOREIGN KEY (`performance_id`) REFERENCES `performance` (`performance_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [36] seat
CREATE TABLE `seat` (
  `seat_id` bigint NOT NULL AUTO_INCREMENT,
  `performance_id` bigint NOT NULL,
  `section` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `seat_row` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `seat_number` int NOT NULL,
  `grade` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `price` int NOT NULL,
  PRIMARY KEY (`seat_id`),
  UNIQUE KEY `uk_seat_unique` (`performance_id`,`section`,`seat_row`,`seat_number`),
  CONSTRAINT `fk_seat_perf` FOREIGN KEY (`performance_id`) REFERENCES `performance` (`performance_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=512 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [37] seat_inventory
CREATE TABLE `seat_inventory` (
  `inventory_id` bigint NOT NULL AUTO_INCREMENT,
  `schedule_id` bigint NOT NULL,
  `seat_id` bigint NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AVAILABLE',
  `hold_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PUBLIC',
  `held_by` bigint DEFAULT NULL,
  `held_until` datetime DEFAULT NULL,
  `version` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`inventory_id`),
  UNIQUE KEY `uk_inv_pair` (`schedule_id`,`seat_id`),
  CONSTRAINT `fk_inv_holder` FOREIGN KEY (`held_by`) REFERENCES `member` (`member_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_inv_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedule` (`schedule_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_inv_seat` FOREIGN KEY (`seat_id`) REFERENCES `seat` (`seat_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1024 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [38] venue_seat_template
CREATE TABLE `venue_seat_template` (
  `template_id` bigint NOT NULL AUTO_INCREMENT,
  `venue_id` bigint NOT NULL,
  `section_id` bigint NOT NULL,
  `seat_row` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `seat_number` int NOT NULL,
  `seat_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NORMAL',
  PRIMARY KEY (`template_id`),
  UNIQUE KEY `uk_vst_seat` (`venue_id`,`section_id`,`seat_row`,`seat_number`),
  CONSTRAINT `fk_vst_section` FOREIGN KEY (`section_id`) REFERENCES `venue_section` (`section_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_vst_venue` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`venue_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=512 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [39] coupon_template
CREATE TABLE `coupon_template` (
  `template_id` bigint NOT NULL AUTO_INCREMENT,
  `promoter_id` bigint DEFAULT NULL,
  `performance_id` bigint DEFAULT NULL,
  `code_prefix` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `discount_type` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'FIXED',
  `discount_value` int NOT NULL,
  `min_amount` int NOT NULL DEFAULT '0',
  `max_discount` int DEFAULT NULL,
  `total_quantity` int NOT NULL DEFAULT '0',
  `issued_count` int NOT NULL DEFAULT '0',
  `valid_from` datetime DEFAULT NULL,
  `valid_until` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`template_id`),
  CONSTRAINT `fk_ct_perf` FOREIGN KEY (`performance_id`) REFERENCES `performance` (`performance_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ct_promoter` FOREIGN KEY (`promoter_id`) REFERENCES `promoter` (`promoter_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [40] reservation
CREATE TABLE `reservation` (
  `reservation_id` bigint NOT NULL AUTO_INCREMENT,
  `reservation_no` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `schedule_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `total_amount` int NOT NULL,
  `seat_count` int NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `confirmed_at` datetime DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  PRIMARY KEY (`reservation_id`),
  UNIQUE KEY `uk_reservation_no` (`reservation_no`),
  CONSTRAINT `fk_reservation_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_reservation_sched` FOREIGN KEY (`schedule_id`) REFERENCES `schedule` (`schedule_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [41] reservation_seat
CREATE TABLE `reservation_seat` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `reservation_id` bigint NOT NULL,
  `seat_id` bigint NOT NULL,
  `price` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rs_pair` (`reservation_id`,`seat_id`),
  CONSTRAINT `fk_rs_reservation` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rs_seat` FOREIGN KEY (`seat_id`) REFERENCES `seat` (`seat_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [42] reservation_waitlist
CREATE TABLE `reservation_waitlist` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `schedule_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'WAITING',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wait` (`schedule_id`,`member_id`),
  CONSTRAINT `fk_wait_mem` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wait_sch` FOREIGN KEY (`schedule_id`) REFERENCES `schedule` (`schedule_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [43] coupon
CREATE TABLE `coupon` (
  `coupon_id` bigint NOT NULL AUTO_INCREMENT,
  `template_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `coupon_code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ISSUED',
  `used_at` datetime DEFAULT NULL,
  `reservation_id` bigint DEFAULT NULL,
  `issued_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`coupon_id`),
  UNIQUE KEY `uk_coupon_code` (`coupon_code`),
  CONSTRAINT `fk_coupon_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_coupon_reservation` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_coupon_template` FOREIGN KEY (`template_id`) REFERENCES `coupon_template` (`template_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [44] entrance_log
CREATE TABLE `entrance_log` (
  `entrance_log_id` bigint NOT NULL AUTO_INCREMENT,
  `reservation_id` bigint NOT NULL,
  `schedule_id` bigint NOT NULL,
  `venue_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `checked_in_by` bigint DEFAULT NULL,
  `note` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `checked_in_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`entrance_log_id`),
  UNIQUE KEY `uk_el_reservation` (`reservation_id`),
  CONSTRAINT `fk_el_checker` FOREIGN KEY (`checked_in_by`) REFERENCES `member` (`member_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_el_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_el_reservation` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_el_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedule` (`schedule_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_el_venue` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`venue_id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [45] payment
CREATE TABLE `payment` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `reservation_id` bigint NOT NULL,
  `member_id` bigint NOT NULL,
  `amount` int NOT NULL,
  `coupon_id` bigint DEFAULT NULL,
  `discount_amount` int NOT NULL DEFAULT '0',
  `final_amount` int NOT NULL,
  `method` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CARD',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `idempotency_key` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pg_transaction_id` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fail_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_payment_idem` (`idempotency_key`),
  CONSTRAINT `fk_payment_member` FOREIGN KEY (`member_id`) REFERENCES `member` (`member_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_payment_reservation` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

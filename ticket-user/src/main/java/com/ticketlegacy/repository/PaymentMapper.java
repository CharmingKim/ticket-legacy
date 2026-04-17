package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Payment;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface PaymentMapper {
    int insert(Payment payment);
    Payment findByIdempotencyKey(@Param("idempotencyKey") String key);
    int updateCompleted(@Param("paymentId") Long paymentId,
                        @Param("pgTransactionId") String pgTxId);
    int updateFailed(@Param("paymentId") Long paymentId,
                     @Param("failureReason") String reason);
    List<Payment> findStalePending(@Param("minutesAgo") int minutesAgo);
}

package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Payment;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface PaymentMapper {
    int insert(Payment payment);
    Payment findByIdempotencyKey(@Param("idempotencyKey") String key);
    int updateCompleted(@Param("id") Long id,
                        @Param("pgTransactionId") String pgTxId);
    int updateFailed(@Param("id") Long id,
                     @Param("failReason") String reason);
    List<Payment> findStalePending(@Param("minutes") int minutes);
}

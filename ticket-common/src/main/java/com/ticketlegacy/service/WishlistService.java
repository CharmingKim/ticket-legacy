package com.ticketlegacy.service;

import com.ticketlegacy.domain.Wishlist;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.WishlistMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class WishlistService {

    @Autowired
    private WishlistMapper wishlistMapper;

    @Transactional
    public boolean toggleWish(Long memberId, Long performanceId) {
        int count = wishlistMapper.checkWish(memberId, performanceId);
        if (count > 0) {
            wishlistMapper.delete(memberId, performanceId);
            return false; // Removed
        } else {
            try {
                wishlistMapper.insert(memberId, performanceId);
                return true; // Added
            } catch (Exception e) {
                // Ignore duplicates or foreign key constraint issues silently
                return false;
            }
        }
    }

    public boolean isWished(Long memberId, Long performanceId) {
        if (memberId == null) return false;
        return wishlistMapper.checkWish(memberId, performanceId) > 0;
    }

    public List<Wishlist> getWishlist(Long memberId) {
        return wishlistMapper.findByMemberId(memberId);
    }
}

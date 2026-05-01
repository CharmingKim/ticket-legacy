package com.ticketlegacy.dto.response;

import lombok.Getter;

import java.util.List;

/**
 * 페이지네이션 응답 표준 래퍼.
 * 컨트롤러에서 Map.of("list", ..., "total", ..., "page", ...) 패턴을 대체한다.
 */
@Getter
public class PageResponse<T> {

    private final List<T> content;
    private final int     page;
    private final int     size;
    private final int     totalElements;
    private final int     totalPages;
    private final boolean first;
    private final boolean last;

    private PageResponse(List<T> content, int page, int size, int totalElements) {
        this.content       = content;
        this.page          = page;
        this.size          = size;
        this.totalElements = totalElements;
        this.totalPages    = size > 0 ? (int) Math.ceil((double) totalElements / size) : 0;
        this.first         = page == 1;
        this.last          = page >= this.totalPages || this.totalPages == 0;
    }

    public static <T> PageResponse<T> of(List<T> content, int totalElements, int page, int size) {
        return new PageResponse<>(content, page, size, totalElements);
    }
}

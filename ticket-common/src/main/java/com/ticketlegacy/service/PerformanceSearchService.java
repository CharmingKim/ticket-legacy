package com.ticketlegacy.service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.search.SearchRequest;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.client.RequestOptions;
import org.elasticsearch.client.RestHighLevelClient;
import org.elasticsearch.common.unit.Fuzziness;
import org.elasticsearch.index.query.BoolQueryBuilder;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.search.SearchHit;
import org.elasticsearch.search.builder.SearchSourceBuilder;
import org.elasticsearch.search.fetch.subphase.highlight.HighlightBuilder;
import org.elasticsearch.search.sort.SortOrder;
import org.elasticsearch.xcontent.XContentType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ticketlegacy.domain.Performance;

@Service
public class PerformanceSearchService {
    private static final Logger log = LoggerFactory.getLogger(PerformanceSearchService.class);
    private static final String INDEX = "performances";

    @Autowired private RestHighLevelClient client;
    @Autowired private ObjectMapper objectMapper;

    // 대기업급 동의어 사전 (확장 가능)
    private static final Map<String, String[]> SYNONYMS = Map.of(
        "아이유", new String[]{"IU", "이지은"},
        "IU",     new String[]{"아이유", "이지은"},
        "BTS",    new String[]{"방탄", "방탄소년단"},
        "방탄",    new String[]{"BTS", "방탄소년단"},
        "임영웅", new String[]{"HERO", "영웅시대"}
    );

    /** 공연 정보를 ES에 비동기로 인덱싱 (메인 트랜잭션 지연 방지) */
    @org.springframework.scheduling.annotation.Async
    public void indexPerformance(Performance p) {
        try {
            String json = objectMapper.writeValueAsString(p);
            IndexRequest request = new IndexRequest(INDEX)
                    .id(p.getPerformanceId().toString())
                    .source(json, XContentType.JSON);
            client.index(request, RequestOptions.DEFAULT);
            log.info("Performance indexed: id={}, title={}", p.getPerformanceId(), p.getTitle());
        } catch (Exception e) {
            log.error("Failed to index performance: {}", e.getMessage());
        }
    }

    /** 대기업급 통합 검색 (오타 교정, 하이라이팅, 가중치 튜닝, 정렬 포함) */
    public List<Map<String, Object>> search(String query, int page, int size) {
        return search(query, page, size, "relevance");
    }

    public List<Map<String, Object>> search(String query, int page, int size, String sort) {
        try {
            SearchSourceBuilder sourceBuilder = new SearchSourceBuilder();
            
            // 1. 복합 쿼리 구성
            BoolQueryBuilder boolQuery = QueryBuilders.boolQuery();
            List<String> queryTerms = new ArrayList<>();
            queryTerms.add(query);
            if (SYNONYMS.containsKey(query)) {
                queryTerms.addAll(Arrays.asList(SYNONYMS.get(query)));
            }
            String expandedQuery = String.join(" ", queryTerms);

            boolQuery.should(QueryBuilders.matchPhrasePrefixQuery("title", expandedQuery).boost(10.0f));
            boolQuery.should(QueryBuilders.multiMatchQuery(expandedQuery, "title", "genre", "venueName")
                    .fuzziness(Fuzziness.AUTO)
                    .prefixLength(0) // 첫 글자부터 오타 허용
                    .boost(2.0f));
            boolQuery.should(QueryBuilders.matchQuery("description", expandedQuery).boost(1.0f));

            sourceBuilder.query(boolQuery);

            // 2. 정렬 로직 (Senior Level)
            if ("date_asc".equals(sort)) {
                sourceBuilder.sort("startDate", SortOrder.ASC);
            } else if ("price_asc".equals(sort)) {
                sourceBuilder.sort("minPrice", SortOrder.ASC);
            } else if ("price_desc".equals(sort)) {
                sourceBuilder.sort("minPrice", SortOrder.DESC);
            } else {
                sourceBuilder.sort("_score", SortOrder.DESC); // 기본값: 정확도순
            }

            // 3. 하이라이팅
            HighlightBuilder highlightBuilder = new HighlightBuilder();
            highlightBuilder.field("title").preTags("<em class='tl-highlight'>").postTags("</em>");
            highlightBuilder.field("description").preTags("<em class='tl-highlight'>").postTags("</em>");
            sourceBuilder.highlighter(highlightBuilder);

            sourceBuilder.from((page - 1) * size);
            sourceBuilder.size(size);

            SearchResponse response = client.search(new SearchRequest(INDEX).source(sourceBuilder), RequestOptions.DEFAULT);

            List<Map<String, Object>> results = new ArrayList<>();
            for (SearchHit hit : response.getHits()) {
                Map<String, Object> source = hit.getSourceAsMap();
                if (hit.getHighlightFields().containsKey("title")) {
                    source.put("displayTitle", hit.getHighlightFields().get("title").fragments()[0].string());
                } else {
                    source.put("displayTitle", source.get("title"));
                }
                results.add(source);
            }
            return results;
        } catch (Exception e) {
            log.error("Advanced search failed: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /** 자동완성 (Edge Ngram 또는 Prefix 기반 추천) */
    public List<String> suggest(String query) {
        try {
            SearchSourceBuilder sourceBuilder = new SearchSourceBuilder();
            // 제목(title) 필드에서 접두사 일치 검색
            sourceBuilder.query(QueryBuilders.matchPhrasePrefixQuery("title", query));
            sourceBuilder.size(10);

            SearchRequest request = new SearchRequest(INDEX).source(sourceBuilder);
            SearchResponse response = client.search(request, RequestOptions.DEFAULT);

            List<String> suggestions = new ArrayList<>();
            for (SearchHit hit : response.getHits()) {
                suggestions.add((String) hit.getSourceAsMap().get("title"));
            }
            return suggestions;
        } catch (Exception e) {
            log.error("Suggest failed: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    /** 전체 공연 데이터 재인덱싱 (비동기 처리) */
    @org.springframework.scheduling.annotation.Async
    public void reindexAll(List<Performance> list) {
        for (Performance p : list) {
            indexPerformance(p);
        }
    }
}

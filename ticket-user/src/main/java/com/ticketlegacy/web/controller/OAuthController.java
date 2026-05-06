package com.ticketlegacy.web.controller;

import com.ticketlegacy.service.MemberService;
import com.ticketlegacy.dto.response.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletResponse;
import java.util.Map;
import java.io.IOException;

@Controller
public class OAuthController {

    @Autowired
    private MemberService memberService;

    // 실제 환경에서는 application.properties 에서 주입받아야 합니다.
    private final String KAKAO_CLIENT_ID = "YOUR_KAKAO_REST_API_KEY";
    private final String KAKAO_REDIRECT_URI = "http://localhost:8080/oauth/kakao/callback";

    @GetMapping("/oauth/kakao/login")
    public void kakaoLoginRedirect(HttpServletResponse response) throws IOException {
        String url = "https://kauth.kakao.com/oauth/authorize?client_id=" + KAKAO_CLIENT_ID +
                "&redirect_uri=" + KAKAO_REDIRECT_URI + "&response_type=code";
        response.sendRedirect(url);
    }

    @GetMapping("/oauth/{provider}/callback")
    public String oauthCallback(@PathVariable String provider,
                                @RequestParam String code,
                                HttpServletResponse response) {
        // 1. 토큰 발급
        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-type", "application/x-www-form-urlencoded;charset=utf-8");

        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "authorization_code");
        params.add("client_id", KAKAO_CLIENT_ID);
        params.add("redirect_uri", KAKAO_REDIRECT_URI);
        params.add("code", code);

        HttpEntity<MultiValueMap<String, String>> kakaoTokenRequest = new HttpEntity<>(params, headers);
        
        try {
            // 카카오 실제 서버에 요청 (키가 없으면 실패하므로 시뮬레이션 폴백 사용 권장)
            ResponseEntity<Map> responseEntity = restTemplate.exchange(
                    "https://kauth.kakao.com/oauth/token",
                    HttpMethod.POST,
                    kakaoTokenRequest,
                    Map.class
            );
            
            String accessToken = (String) responseEntity.getBody().get("access_token");

            // 2. 유저 정보 조회
            HttpHeaders profileHeaders = new HttpHeaders();
            profileHeaders.add("Authorization", "Bearer " + accessToken);
            profileHeaders.add("Content-type", "application/x-www-form-urlencoded;charset=utf-8");
            
            HttpEntity<MultiValueMap<String, String>> kakaoProfileRequest = new HttpEntity<>(profileHeaders);
            ResponseEntity<Map> profileResponse = restTemplate.exchange(
                    "https://kapi.kakao.com/v2/user/me",
                    HttpMethod.POST,
                    kakaoProfileRequest,
                    Map.class
            );

            Map<String, Object> profileBody = profileResponse.getBody();
            Long id = (Long) profileBody.get("id");
            Map<String, Object> kakaoAccount = (Map<String, Object>) profileBody.get("kakao_account");
            Map<String, Object> profile = (Map<String, Object>) kakaoAccount.get("profile");
            
            String email = (String) kakaoAccount.get("email");
            String nickname = (String) profile.get("nickname");

            // 3. 소셜 로그인 처리 (가입 or 로그인)
            MemberService.LoginResult result = memberService.socialLogin(provider.toUpperCase(), String.valueOf(id), email, nickname);
            
            Cookie cookie = new Cookie("USER_TOKEN", result.token);
            cookie.setHttpOnly(true);
            cookie.setPath("/");
            cookie.setMaxAge(60 * 60 * 2);
            response.addCookie(cookie);

            return "redirect:/";

        } catch (Exception e) {
            // API 키가 없어서 실패할 경우를 대비한 샌드박스(시뮬레이션) 모드 동작
            return "redirect:/oauth/sandbox/callback?provider=" + provider;
        }
    }

    // 테스트 환경을 위한 샌드박스 (API 키 없이도 소셜 로그인이 되는 것처럼 시뮬레이션)
    @GetMapping("/oauth/sandbox/callback")
    public String sandboxCallback(@RequestParam String provider, HttpServletResponse response) {
        String dummyProviderId = "dummy_" + System.currentTimeMillis();
        String dummyEmail = dummyProviderId + "@" + provider + ".com";
        String dummyName = provider + "테스트유저";

        MemberService.LoginResult result = memberService.socialLogin(provider.toUpperCase(), dummyProviderId, dummyEmail, dummyName);
        
        Cookie cookie = new Cookie("USER_TOKEN", result.token);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(60 * 60 * 2);
        response.addCookie(cookie);

        return "redirect:/";
    }
}

#!/bin/bash
# TicketLegacy 소스 → 배포폴더 동기화 스크립트
# STS "Never publish automatically" 환경에서 수동 배포용
# 사용법: bash deploy-sync.sh [user|partner|admin|all]

BASE="D:/springGreen/springframework/works"
SRC="$BASE/ticket-parent"
TMP="$BASE/.metadata/.plugins/org.eclipse.wst.server.core"

deploy_user() {
    echo "[ticket-user] 동기화 중..."
    SRC_U="$SRC/ticket-user/src/main/webapp"
    DST_U="$TMP/tmp3/wtpwebapps/ticket-user"
    cp -r "$SRC_U/WEB-INF/views/"*  "$DST_U/WEB-INF/views/"
    cp -r "$SRC_U/WEB-INF/spring/"* "$DST_U/WEB-INF/spring/"
    cp -r "$SRC_U/WEB-INF/tiles/"*  "$DST_U/WEB-INF/tiles/"
    cp -r "$SRC_U/resources/"*       "$DST_U/resources/"
    rm -rf "$TMP/tmp3/work/Catalina/localhost/ticket-user/"
    echo "[ticket-user] 완료 (JSP 캐시 삭제됨)"
}

deploy_partner() {
    echo "[ticket-partner] 동기화 중..."
    SRC_P="$SRC/ticket-partner/src/main/webapp"
    DST_P="$TMP/tmp2/wtpwebapps/ticket-partner"
    cp -r "$SRC_P/WEB-INF/views/"*  "$DST_P/WEB-INF/views/"
    cp -r "$SRC_P/WEB-INF/spring/"* "$DST_P/WEB-INF/spring/"
    cp -r "$SRC_P/WEB-INF/tiles/"*  "$DST_P/WEB-INF/tiles/"
    cp -r "$SRC_P/resources/"*       "$DST_P/resources/"
    rm -rf "$TMP/tmp2/work/Catalina/localhost/ticket-partner/"
    echo "[ticket-partner] 완료 (JSP 캐시 삭제됨)"
}

deploy_admin() {
    echo "[ticket-admin] 동기화 중..."
    SRC_A="$SRC/ticket-admin/src/main/webapp"
    DST_A="$TMP/tmp1/wtpwebapps/ticket-admin"
    cp -r "$SRC_A/WEB-INF/views/"*  "$DST_A/WEB-INF/views/"
    cp -r "$SRC_A/WEB-INF/spring/"* "$DST_A/WEB-INF/spring/"
    cp -r "$SRC_A/WEB-INF/tiles/"*  "$DST_A/WEB-INF/tiles/"
    cp -r "$SRC_A/resources/"*       "$DST_A/resources/"
    rm -rf "$TMP/tmp1/work/Catalina/localhost/ticket-admin/"
    echo "[ticket-admin] 완료 (JSP 캐시 삭제됨)"
}

case "${1:-all}" in
    user)    deploy_user ;;
    partner) deploy_partner ;;
    admin)   deploy_admin ;;
    all)     deploy_user; deploy_partner; deploy_admin ;;
    *)       echo "사용법: bash deploy-sync.sh [user|partner|admin|all]" ;;
esac

echo "동기화 완료. STS에서 서버 Restart 하세요."

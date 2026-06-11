$EC2 = "ec2-user@35.171.183.192"
$KEY = "$HOME\.ssh\ticketlegacy-key.pem"
$BASE = "D:\springGreen\springframework\works\ticket-parent"

Write-Host "1/5 ticket-user 전송..."
scp -i $KEY "$BASE\ticket-user\Dockerfile" "$BASE\ticket-user\target\ticket-user.war" "${EC2}:~/ticketlegacy/ticket-user/"

Write-Host "2/5 ticket-partner 전송..."
scp -i $KEY "$BASE\ticket-partner\Dockerfile" "$BASE\ticket-partner\target\ticket-partner.war" "${EC2}:~/ticketlegacy/ticket-partner/"

Write-Host "3/5 ticket-admin 전송..."
scp -i $KEY "$BASE\ticket-admin\Dockerfile" "$BASE\ticket-admin\target\ticket-admin.war" "${EC2}:~/ticketlegacy/ticket-admin/"

Write-Host "4/5 docker-compose + .env 전송..."
scp -i $KEY "$BASE\docker-compose.yml" "$BASE\.env" "${EC2}:~/ticketlegacy/"

Write-Host "5/5 DB SQL 전송..."
scp -i $KEY "$BASE\db\schema_total.sql" "$BASE\db\data_total.sql" "$BASE\db\data_extension.sql" "${EC2}:~/ticketlegacy/db/"

Write-Host "전송 완료!"

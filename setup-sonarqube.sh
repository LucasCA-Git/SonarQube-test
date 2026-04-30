#!/bin/bash

set -e

echo "🔍 Verificando Docker..."
if ! command -v docker &> /dev/null
then
    echo "❌ Docker não está instalado."
    exit 1
fi

echo "🔍 Verificando Docker Compose..."
if ! docker compose version &> /dev/null
then
    echo "📦 Instalando Docker Compose..."
    sudo apt update
    sudo apt install docker-compose-plugin -y
fi

echo "⚙️ Ajustando vm.max_map_count..."
sudo sysctl -w vm.max_map_count=262144
if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
fi

echo "📁 Criando diretório..."
mkdir -p ~/sonarqube
cd ~/sonarqube

echo "📄 Criando docker-compose.yml..."

cat > docker-compose.yml <<EOF
version: "3.8"

services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    depends_on:
      - db
    ports:
      - "127.0.0.1:9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    restart: always

  db:
    image: postgres:13
    container_name: sonarqube_db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - sonarqube_db:/var/lib/postgresql/data
    restart: always

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
  sonarqube_db:
EOF

echo "🚀 Subindo containers..."
docker compose up -d

echo "⏳ Aguardando SonarQube iniciar..."
sleep 20

echo "🔍 Testando serviço..."
if curl -s http://localhost:9000 | grep -q "SonarQube"; then
    echo "✅ SonarQube está rodando!"
else
    echo "⚠️ Pode estar inicializando ainda. Aguarde mais alguns segundos."
fi

echo ""
echo "🌐 Acesse: http://SEU_IP:9000 (interno)"
echo "👤 Login: admin / admin"
echo ""
echo "➡️ Próximo passo: configurar Nginx"
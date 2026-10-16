# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Demo temsilci hesabı. Şifre ENV["AGENT_PASSWORD"]'dan gelir.
# Production'da değişken yoksa seed KeyError ile durur (bilinen bir varsayılan şifreyle canlı hesap açılmasın).
# Yerel varsayılan yalnızca development ve test içindir.
agent_password =
  if Rails.env.production?
    ENV.fetch("AGENT_PASSWORD")
  else
    ENV.fetch("AGENT_PASSWORD", "tempodesk-local-dev")
  end

User.find_or_create_by!(email_address: "agent@tempodesk.example") do |user|
  user.password = agent_password
end

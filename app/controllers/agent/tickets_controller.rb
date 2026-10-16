module Agent
  # Yer tutucu: gerçek bilet listesi Aşama 5'te yazılacak.
  # Kimlik doğrulama ApplicationController'daki Authentication concern'inden gelir.
  class TicketsController < ApplicationController
    def index
      render plain: "Temsilci paneli (bilet listesi Aşama 5'te)"
    end
  end
end

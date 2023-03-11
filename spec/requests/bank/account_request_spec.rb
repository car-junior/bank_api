require 'rails_helper'

RSpec.describe "Accounts Requests", type: :request do
  let(:valid_login_account) do
    valid_login
  end

  let(:invalid_login_account) do
    invalid_login
  end

  describe 'GET /api/v1/accounts INDEX' do
    context 'Quando não existem accounts salvas' do
      it 'retorna array vazio' do
        get api_v1_accounts_path
        expect_json(total_results: 0, results: [])
        expect(response).to have_http_status(200)
      end
    end

    context 'Quando existem accounts salvas' do
      before(:each) do
        @accounts = []
        5.times do
          @accounts << create(:new_account)
        end
      end

      it 'retorna todos os dados da conta' do
        get api_v1_accounts_path
        expect(json_body[:total_results]).to eq(@accounts.length)
        expect_json_keys('results.*', %i[id agency number status balance client])
        expect_json_keys('results.*.client', %i[id name last_name cpf])
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST /api/v1/accounts CREATE' do
    context 'Quando passa dados validos' do
      it 'salva e retorna account' do
        account_attributes = FactoryBot.attributes_for(:new_account)
        account_attributes[:client_attributes] = FactoryBot.attributes_for(:new_client)
        expect do
          post api_v1_accounts_path,
               params: account_attributes
        end.to change { Bank::Model::Account.count }.by(1)

        expect(response).to have_http_status(201)
        expect_json_keys(%i[id agency number balance client])
        expect_json_keys('client', %i[id name last_name cpf email date_of_birth])
      end
    end
  end

  describe 'GET /api/v1/accounts/:id SHOW' do
    before(:each) do
      @account = create(:new_account)
    end

    context 'Quando cliente está autenticado' do
      context 'Quando passa id respectivo da conta do cliente' do
        it 'retorna 200' do
          get api_v1_account_path(id: valid_login_account[:id]),
              headers: { 'Authorization': "Bearer #{valid_login_account[:token]}" }
          account = Bank::Model::Account.find(valid_login_account[:id])
          expect(response).to have_http_status(200)
          expect_json_keys(%i[id agency number balance])
          expect_json_keys('client.', %i[id name last_name cpf email date_of_birth])
          expect_json(id: account.id, agency: account.agency, number: account.number, balance: account.balance.to_s)
          expect_json('client', id: account.client.id, name: account.client.name, last_name: account.client.last_name,
                      cpf: account.client.cpf, email: account.client.email)
        end
      end

      context 'Quando passa id diferente da sua conta autenticada' do
        it 'retorna 403' do
          get api_v1_account_path(id: @account.id),
              headers: { 'Authorization': "Bearer #{valid_login_account[:token]}" }

          expect(response).to have_http_status(403)

        end
      end

    end

    context 'Quando client não está autenticado' do
      it 'retorna 401' do
        get api_v1_account_path(id: invalid_login_account[:id])
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'PUT /api/v1/accounts/:id UPDATE' do
    before(:each) do
      @account = create(:new_account)
    end

    context 'Quando cliente está autenticado' do
      context 'Quando passa id respectivo da conta do cliente' do
        it 'atualiza dados e retorna 200' do
          params_account = { id: valid_login_account[:id] }
          params_account[:clients_attributes] = {
            last_name: 'Ciclano Silva',
            email: 'ciclanosilva@gmail.com'
          }

          put api_v1_account_path(id: valid_login_account[:id]),
              headers: { 'Authorization': "Bearer #{valid_login_account[:token]}" },
              params: params_account

          account = Bank::Model::Account.find(valid_login_account[:id])

          expect(response).to have_http_status(200)
          expect_json_keys(%i[id agency number balance])
          expect_json_keys('client.', %i[id name last_name cpf email date_of_birth])
          expect_json(id: account.id)
          expect_json('client', id: account.client.id, last_name: account.client.last_name, email: account.client.email)
        end
      end

      context 'Quando passa id diferente da sua conta autenticada' do
        it 'não atualiza dados e retorna 403' do
          put api_v1_account_path(id: @account.id),
              headers: { 'Authorization': "Bearer #{valid_login_account[:token]}" },
              params: attributes_for(:new_client)
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'Quando cliente não está autenticado' do
      it 'não atualiza dados e retorna 401' do
        put api_v1_account_path(id: valid_login_account[:id]),
            params: attributes_for(:new_client)
        expect(response).to have_http_status(401)
      end
    end
  end


end

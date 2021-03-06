require 'spec_helper'

module Pageflow
  describe ::Admin::UsersController do
    describe '#create' do
      it 'does not allow account managers to create admins' do
        account = create(:account)
        user = create(:user, :editor, :account => account)

        sign_in(create(:user, :account_manager, :account => account))

        expect {
          post :create, :user => attributes_for(:valid_user, :role => 'admin')
        }.not_to change { User.admins.count }
      end

      it 'allows admins to create admins' do
        sign_in(create(:user, :admin))

        expect {
          post :create, :user => attributes_for(:valid_user, :role => 'admin')
        }.to change { User.admins.count }
      end

      it 'does not allow account manager to create user for other account' do
        account = create(:account)

        sign_in(create(:user, :account_manager))

        expect {
          post :create, :user => attributes_for(:valid_user, :account_id => account)
        }.not_to change { account.users.count }
      end

      it 'allows account manager to create users for own account' do
        account = create(:account)

        sign_in(create(:user, :account_manager, :account => account))

        expect {
          post :create, :user => attributes_for(:valid_user)
        }.to change { account.users.count }
      end

      it 'allows admin to set user account' do
        account = create(:account)

        sign_in(create(:user, :admin))

        expect {
          post :create, :user => attributes_for(:valid_user, :account_id => account)
        }.to change { account.users.count }
      end
    end

    describe '#update' do
      it 'does not allow account managers to make users admin' do
        account = create(:account)
        user = create(:user, :editor, :account => account)

        sign_in(create(:user, :account_manager, :account => account))
        patch :update, :id => user, :user => {:role => 'admin'}

        expect(user.reload).not_to be_admin
      end

      it 'allows admin to make users admin' do
        user = create(:user, :editor)

        sign_in(create(:user, :admin))
        patch :update, :id => user, :user => {:role => 'admin'}

        expect(user.reload).to be_admin
      end

      it 'does not allow account manager to change user account' do
        account = create(:account)
        other_account = create(:account)
        user = create(:user, :editor, :account => account)

        sign_in(create(:user, :account_manager, :account => account))
        patch :update, :id => user, :user => {:account_id => other_account}

        expect(user.reload.account).to eq(account)
      end

      it 'allows admin to change user account' do
        account = create(:account)
        other_account = create(:account)
        user = create(:user, :editor, :account => account)

        sign_in(create(:user, :admin))
        patch :update, :id => user, :user => {:account_id => other_account}

        expect(user.reload.account).to eq(other_account)
      end
    end
  end
end

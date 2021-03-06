require 'test_helper'

class UserDeletionTest < ActiveSupport::TestCase
  context "an invalid user deletion" do
    context "for an invalid password" do
      should "fail" do
        @user = create(:user)
        @deletion = UserDeletion.new(@user, "wrongpassword")

        assert_raise(UserDeletion::ValidationError) do
          @deletion.delete!
        end
      end
    end

    context "for an admin" do
      should "fail" do
        @user = create(:admin_user)
        @deletion = UserDeletion.new(@user, "password")

        assert_raise(UserDeletion::ValidationError) do
          @deletion.delete!
        end
      end
    end
  end

  context "a valid user deletion" do
    setup do
      @user = create(:user, email_address: build(:email_address))
      @deletion = UserDeletion.new(@user, "password")
    end

    should "blank out the email" do
      @deletion.delete!
      assert_nil(@user.reload.email_address)
    end

    should "rename the user" do
      @deletion.delete!
      assert_equal("user_#{@user.id}", @user.reload.name)
    end

    should "reset the password" do
      @deletion.delete!
      assert_equal(false, @user.authenticate_password("password"))
    end

    should "remove any favorites" do
      @post = create(:post)
      Favorite.add(post: @post, user: @user)

      perform_enqueued_jobs { @deletion.delete! }

      assert_equal(0, Favorite.count)
      assert_equal("", @post.reload.fav_string)
      assert_equal(0, @post.fav_count)
    end
  end
end

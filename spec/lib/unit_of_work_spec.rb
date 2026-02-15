require "rails_helper"

RSpec.describe UnitOfWork do
  describe "#execute" do
    let(:executor) { create(:user) }
    let(:target_user) { create(:user) }
    let(:executor_id) { executor.id }
    let(:validation_error) { nil }
    let(:raised_error) { nil }
    let(:new_email) { "changed_email@example.com" }
    let(:params) { {user_id: target_user.id, new_email:} }
    let(:unit_of_work_class) { get_unit_of_work_class }

    context "when execute_unit_of_work finishes with no errors" do
      it "stores a successful execution record and commits the transaction" do
        result = act

        aggregate_failures do
          expect(result.success?).to be(true), result.errors.full_messages.join(", ")
          assert_execution_record(result: 'success')
          expect(target_user.reload.email).to eq(new_email)
        end
      end
    end

    context "when execute_unit_of_work adds errors to the errors object" do
      let(:validation_error) { "some validation error" }
      it "stores a failed execution record and rolls back the transaction" do
        result = act
        assert_failed_execution(result)
      end
    end

    context "when execute_unit_of_work raises an error" do
      let(:raised_error) { RuntimeError.new("boom") }

      it "stores a failed execution record and rolls back the transaction" do
        result = act
        assert_failed_execution(result)
        expect(result.errors.full_messages).to include(raised_error.message)
      end
    end

    context 'with audit_params defined' do
      let(:unit_of_work_class) do
        klass = get_unit_of_work_class
        klass.define_method(:audit_params) do
          {foo: "bar"}
        end
        klass
      end

      it 'saves the audit params to the execution record' do
        result = act
        assert_execution_record(result: 'success', params: {foo: "bar"})
      end
    end

    context "when execute_unit_of_work calls another unit of work" do
      it "only stores an audit record for the outer unit of work" do
        result = nil

        expect {
          result = nested_unit_of_work_class.execute(executor_id:, params:)
        }.to change(UnitOfWorkExecution, :count).by(1)

        aggregate_failures do
          expect(result.success?).to be(true), result.errors.full_messages.join(", ")
          assert_execution_record(result: "success", expected_unit_of_work: "UnitOfWork::OuterImplementation")
        end
      end
    end

    private

    def act
      klass = unit_of_work_class
      instance = klass.new(executor_id:, params:)
      instance.validation_error = validation_error
      instance.raised_error = raised_error
      instance.execute
    end

    def get_unit_of_work_class
      stub_const("UnitOfWork::TestImplementation", Class.new(UnitOfWork) do
        attr_accessor :validation_error, :raised_error

        private

        def execute_unit_of_work(errors:)
          user.update!(email: params[:new_email])
          errors.add(:base, validation_error) if validation_error.present?
          raise raised_error if raised_error.present?
        end

        def user
          @user ||= User.find(params[:user_id])
        end
      end)
    end

    def nested_unit_of_work_class
      stub_const("UnitOfWork::InnerImplementation", Class.new(UnitOfWork) do
        private

        def execute_unit_of_work(errors:)
          errors
        end
      end)

      stub_const("UnitOfWork::OuterImplementation", Class.new(UnitOfWork) do
        private

        def execute_unit_of_work(errors:)
          errors
          UnitOfWork::InnerImplementation.execute(executor_id:, params:)
        end
      end)
    end

    def assert_execution_record(result:, params: nil, expected_unit_of_work: "UnitOfWork::TestImplementation")
      params ||= self.params
      execution = UnitOfWorkExecution.order(:created_at).last
      expect(execution).not_to be_nil
      expect(execution.executor_id).to eq(executor_id)
      expect(execution.unit_of_work).to eq(expected_unit_of_work)
      expect(execution.started_at).to be_present
      expect(execution.completed_at).to be_present
      expect(execution.params).to eq(params.as_json)
      expect(execution.result).to eq(result)
    end

    def assert_failed_execution(result)
      aggregate_failures do
        expect(result.success?).to be(false)
        assert_execution_record(result: 'failure')
        expect(target_user.reload.email).not_to eq(new_email)
      end
    end
  end
end

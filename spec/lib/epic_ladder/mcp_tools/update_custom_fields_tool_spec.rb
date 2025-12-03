# frozen_string_literal: true

require_relative '../../../rails_helper'

RSpec.describe EpicLadder::McpTools::UpdateCustomFieldsTool, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) { create(:role, permissions: %i[view_issues edit_issues]) }
  let(:member) { create(:member, project: project, user: user, roles: [role]) }
  let(:task_tracker) do
    Tracker.create!(
      name: EpicLadder::TrackerHierarchy.tracker_names[:task],
      default_status: IssueStatus.first
    )
  end
  let(:custom_field) do
    cf = IssueCustomField.create!(
      name: 'TestField',
      field_format: 'string',
      is_for_all: true,
      trackers: [task_tracker]
    )
    cf
  end
  let(:custom_field2) do
    IssueCustomField.create!(
      name: 'EstimatedHours',
      field_format: 'float',
      is_for_all: true,
      trackers: [task_tracker]
    )
  end
  let(:task) do
    create(:issue,
           project: project,
           tracker: task_tracker)
  end

  before do
    member
    project.trackers << task_tracker unless project.trackers.include?(task_tracker)
    custom_field
    custom_field2
    project.issue_custom_fields << custom_field unless project.issue_custom_fields.include?(custom_field)
    project.issue_custom_fields << custom_field2 unless project.issue_custom_fields.include?(custom_field2)
  end

  describe '.call' do
    let(:server_context) { { user: user } }

    context 'with valid parameters' do
      it 'updates custom field by name' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: { 'TestField' => 'New Value' },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['issue_id']).to eq(task.id.to_s)
        expect(response_text['updated_fields'].first['field_name']).to eq('TestField')
        expect(response_text['updated_fields'].first['new_value']).to eq('New Value')

        task.reload
        expect(task.custom_field_value(custom_field.id)).to eq('New Value')
      end

      it 'updates custom field by ID' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: { custom_field.id.to_s => 'Value By ID' },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['updated_fields'].first['new_value']).to eq('Value By ID')

        task.reload
        expect(task.custom_field_value(custom_field.id)).to eq('Value By ID')
      end

      it 'updates multiple custom fields at once' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: {
            'TestField' => 'Value1',
            'EstimatedHours' => '8.5'
          },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['updated_fields'].size).to eq(2)

        task.reload
        expect(task.custom_field_value(custom_field.id)).to eq('Value1')
        expect(task.custom_field_value(custom_field2.id)).to eq('8.5')
      end

      it 'finds custom field case-insensitively' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: { 'testfield' => 'Case Insensitive' },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true

        task.reload
        expect(task.custom_field_value(custom_field.id)).to eq('Case Insensitive')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when issue not found' do
        result = described_class.call(
          issue_id: '99999',
          custom_fields: { 'TestField' => 'Value' },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('チケットが見つかりません')
      end

      it 'returns warning when custom field not found' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: {
            'TestField' => 'Valid Value',
            'NonExistentField' => 'Invalid'
          },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be true
        expect(response_text['updated_fields'].size).to eq(1)
        expect(response_text['warnings']).to include(/カスタムフィールドが見つかりません.*NonExistentField/)
      end

      it 'returns error when all custom fields not found' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: { 'NonExistentField' => 'Invalid' },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('カスタムフィールドが見つかりません')
      end
    end

    context 'without permission' do
      let(:role_without_permission) { create(:role, permissions: [:view_issues]) }
      let(:member_without_permission) do
        create(:member, project: project, user: user, roles: [role_without_permission])
      end

      before do
        member.destroy
        member_without_permission
      end

      it 'returns permission error' do
        result = described_class.call(
          issue_id: task.id.to_s,
          custom_fields: { 'TestField' => 'Value' },
          server_context: server_context
        )

        response_text = JSON.parse(result.content.first[:text])

        expect(response_text['success']).to be false
        expect(response_text['error']).to include('権限がありません')
      end
    end
  end
end

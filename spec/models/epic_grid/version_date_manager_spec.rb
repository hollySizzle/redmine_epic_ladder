# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicGrid::VersionDateManager do
  let(:user) { create(:user) }
  let(:tracker) { create(:user_story_tracker) }
  let(:project) do
    proj = create(:project)
    proj.trackers << tracker unless proj.trackers.include?(tracker)
    proj
  end
  let(:issue) do
    create(:user_story, project: project, author: user)
  end

  describe '.update_dates_for_version_change' do
    context 'バージョンがnilの場合' do
      it 'nilを返す' do
        result = described_class.update_dates_for_version_change(issue, nil)
        expect(result).to be_nil
      end
    end

    context 'バージョンの期日が未設定の場合' do
      let(:version) { create(:version, project: project, effective_date: nil) }

      it 'nilを返す' do
        result = described_class.update_dates_for_version_change(issue, version)
        expect(result).to be_nil
      end
    end

    context '新バージョンより早いバージョンが存在しない場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }

      it '開始日と終了日の両方が新バージョンの期日になる' do
        result = described_class.update_dates_for_version_change(issue, version_a)

        expect(result[:start_date]).to eq(Date.new(2025, 10, 10))
        expect(result[:due_date]).to eq(Date.new(2025, 10, 10))
      end
    end

    context '新バージョンより早いバージョンが存在する場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 5)) }
      let!(:version_b) { create(:version, project: project, name: 'v1.1', effective_date: Date.new(2025, 10, 10)) }
      let!(:version_c) { create(:version, project: project, name: 'v1.2', effective_date: Date.new(2025, 10, 15)) }

      context 'バージョンBに移動する場合' do
        it '開始日が直前のバージョンAの期日、終了日がバージョンBの期日になる' do
          result = described_class.update_dates_for_version_change(issue, version_b)

          expect(result[:start_date]).to eq(Date.new(2025, 10, 5))  # version_a（直前のバージョン）
          expect(result[:due_date]).to eq(Date.new(2025, 10, 10))   # version_b
        end
      end

      context 'バージョンCに移動する場合' do
        it '開始日が直前のバージョンBの期日、終了日がバージョンCの期日になる' do
          result = described_class.update_dates_for_version_change(issue, version_c)

          expect(result[:start_date]).to eq(Date.new(2025, 10, 10))  # version_b（直前のバージョン）
          expect(result[:due_date]).to eq(Date.new(2025, 10, 15))   # version_c
        end
      end

      context '最も早いバージョンAに移動する場合' do
        it '開始日と終了日の両方がバージョンAの期日になる' do
          result = described_class.update_dates_for_version_change(issue, version_a)

          expect(result[:start_date]).to eq(Date.new(2025, 10, 5))
          expect(result[:due_date]).to eq(Date.new(2025, 10, 5))
        end
      end
    end

    context '期日が未設定のバージョンが混在する場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 5)) }
      let!(:version_b) { create(:version, project: project, name: 'v1.1', effective_date: nil) }
      let!(:version_c) { create(:version, project: project, name: 'v1.2', effective_date: Date.new(2025, 10, 15)) }

      it '期日が未設定のバージョンはスキップされ、直前の期日ありバージョンが開始日になる' do
        result = described_class.update_dates_for_version_change(issue, version_c)

        expect(result[:start_date]).to eq(Date.new(2025, 10, 5))  # version_a（直前の期日ありバージョン、version_bはスキップ）
        expect(result[:due_date]).to eq(Date.new(2025, 10, 15))   # version_c
      end
    end

    context '異なるプロジェクトのバージョンが存在する場合' do
      let(:other_project) { create(:project) }
      let!(:other_version) { create(:version, project: other_project, name: 'other', effective_date: Date.new(2025, 9, 1)) }
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }

      it '同じプロジェクトのバージョンのみが対象になる' do
        result = described_class.update_dates_for_version_change(issue, version_a)

        expect(result[:start_date]).to eq(Date.new(2025, 10, 10))
        expect(result[:due_date]).to eq(Date.new(2025, 10, 10))
      end
    end
  end
end

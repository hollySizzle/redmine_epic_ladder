import React from 'react';
import { Dropdown, DropdownLabel, DropdownSection, DropdownSeparator } from './Dropdown';
import { SortSelector } from './SortSelector';
import { VerticalModeToggle } from './VerticalModeToggle';
import { AssignedToToggle } from './AssignedToToggle';
import { DueDateToggle } from './DueDateToggle';
import { IssueIdToggle } from './IssueIdToggle';
import { DetailPaneToggle } from './DetailPaneToggle';

export const SettingsDropdown: React.FC = () => {
  return (
    <Dropdown
      align="end"
      trigger={
        <button className="settings-dropdown-trigger" title="表示設定">
          ⚙️ 表示設定
        </button>
      }
    >
      {/* ソート設定 */}
      <DropdownLabel>ソート設定</DropdownLabel>

      <DropdownSection>
        <SortSelector type="epic" label="Epic&Feature並び替え" />
      </DropdownSection>

      <DropdownSection>
        <SortSelector type="version" label="Version並び替え" />
      </DropdownSection>

      <DropdownSeparator />

      {/* 表示オプション */}
      <DropdownLabel>表示オプション</DropdownLabel>

      <DropdownSection>
        <VerticalModeToggle />
      </DropdownSection>

      <DropdownSection>
        <AssignedToToggle />
      </DropdownSection>

      <DropdownSection>
        <DueDateToggle />
      </DropdownSection>

      <DropdownSection>
        <IssueIdToggle />
      </DropdownSection>

      <DropdownSection>
        <DetailPaneToggle />
      </DropdownSection>
    </Dropdown>
  );
};

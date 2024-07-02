import CollectionPreferences from "@cloudscape-design/components/collection-preferences";
import { useMemo } from "react";
import { useLocalStorage } from "../local-storage";
import { mapWithColumnDefinitionIds, addToColumnDefinitions } from "../table";

export const DEFAULT_VISIBLE_CONTENT_LIST = [
  "name",
  "createdAt",
];

export const MyPreferences = ({
  preferences,
  setPreferences,
}) => (
  <CollectionPreferences
    disabled={preferences.disabled}
    preferences={preferences}
    onConfirm={({ detail }) => setPreferences({...preferences, ...detail})}
    pageSizePreference={preferences.pageSizePreference}
    wrapLinesPreference={preferences.wrapLinesPreference}
    stripedRowsPreference={preferences.stripedRowsPreference}
    contentDensityPreference={preferences.contentDensityPreference}
    contentDisplayPreference={preferences.contentDisplayPreference}
    visibleContentPreference={preferences.visibleContentPreference}
    stickyColumnsPreference={preferences.stickyColumnsPreference}
  />
);

export function useColumnWidths(storageKey, columnDefinitions) {
  const [widths, saveWidths] = useLocalStorage(storageKey);

  function handleWidthChange(event) {
    saveWidths(
      mapWithColumnDefinitionIds(
        columnDefinitions,
        "width",
        event.detail.widths
      )
    );
  }
  const memoDefinitions = useMemo(() => {
    return addToColumnDefinitions(columnDefinitions, "width", widths);
  }, [widths, columnDefinitions]);

  return [memoDefinitions, handleWidthChange];
}

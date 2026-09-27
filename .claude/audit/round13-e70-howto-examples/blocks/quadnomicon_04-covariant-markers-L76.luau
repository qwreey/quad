export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }

export type SlotMarker<T> = { read __quadSlot: true, read __quadSlotValue: T }

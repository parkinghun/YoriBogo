//
//  DatePickerTextField.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit

final class DatePickerTextField: UITextField {

    // MARK: - Properties
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")
        picker.minimumDate = Calendar.current.startOfDay(for: Date())
        return picker
    }()

    var onDateSelected: ((Date?) -> Void)?
    var dateFormatter: DateFormatter = DateFormatter.expirationDate

    // MARK: - Initialization
    init(showClearButton: Bool = true) {
        super.init(frame: .zero)
        setupDatePicker(showClearButton: showClearButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupDatePicker(showClearButton: Bool) {
        inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        var items: [UIBarButtonItem] = []

        if showClearButton {
            let clearButton = UIBarButtonItem(
                title: "삭제",
                style: .plain,
                target: self,
                action: #selector(clearDate)
            )
            items.append(clearButton)
        }

        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        items.append(flexSpace)

        let doneButton = UIBarButtonItem(
            title: "완료",
            style: .done,
            target: self,
            action: #selector(datePickerDone)
        )
        items.append(doneButton)

        toolbar.items = items
        inputAccessoryView = toolbar
    }

    // MARK: - Actions
    @objc private func datePickerDone() {
        let selectedDate = datePicker.date
        text = dateFormatter.string(from: selectedDate)
        onDateSelected?(selectedDate)
        resignFirstResponder()
    }

    @objc private func clearDate() {
        text = nil
        onDateSelected?(nil)
        resignFirstResponder()
    }

    // MARK: - Public Methods
    func setDate(_ date: Date?) {
        guard let date = date else {
            text = nil
            return
        }
        datePicker.date = date
        text = dateFormatter.string(from: date)
    }

    func getDate() -> Date? {
        guard let _ = text, !text!.isEmpty else { return nil }
        return datePicker.date
    }
}

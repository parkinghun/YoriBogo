//
//  RecipeAddViewController+Ingredient.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-15.
//

import UIKit
import SnapKit

// MARK: - Ingredient Management
extension RecipeAddViewController {

    func addInitialIngredient() {
        let ingredientView = createIngredientView()
        ingredientsStackView.addArrangedSubview(ingredientView)
    }

    func createIngredientView() -> UIView {
        let containerView = UIView()

        let nameTextField = UITextField()
        nameTextField.placeholder = "재료명"
        nameTextField.font = .systemFont(ofSize: 16)
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = .gray50
        nameTextField.layer.cornerRadius = 12
        nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameTextField.leftViewMode = .always
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(ingredientTextFieldDidChange), for: .editingChanged)

        let qtyTextField = UITextField()
        qtyTextField.placeholder = "1"
        qtyTextField.font = .systemFont(ofSize: 16)
        qtyTextField.borderStyle = .none
        qtyTextField.backgroundColor = .gray50
        qtyTextField.layer.cornerRadius = 12
        qtyTextField.textAlignment = .center
        qtyTextField.keyboardType = .decimalPad
        qtyTextField.returnKeyType = .done
        qtyTextField.delegate = self
        qtyTextField.addTarget(self, action: #selector(ingredientTextFieldDidChange), for: .editingChanged)

        let unitTextField = UITextField()
        unitTextField.placeholder = "개"
        unitTextField.font = .systemFont(ofSize: 16)
        unitTextField.borderStyle = .none
        unitTextField.backgroundColor = .gray50
        unitTextField.layer.cornerRadius = 12
        unitTextField.textAlignment = .center
        unitTextField.returnKeyType = .done
        unitTextField.delegate = self
        unitTextField.addTarget(self, action: #selector(ingredientTextFieldDidChange), for: .editingChanged)

        containerView.addSubview(nameTextField)
        containerView.addSubview(qtyTextField)
        containerView.addSubview(unitTextField)

        nameTextField.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.height.equalTo(52)
        }

        qtyTextField.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalTo(nameTextField.snp.trailing).offset(8)
            $0.width.equalTo(70)
        }

        unitTextField.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(qtyTextField.snp.trailing).offset(8)
            $0.width.equalTo(80)
        }

        return containerView
    }

    @objc func addIngredientTapped() {
        let ingredientView = createIngredientView()
        ingredientsStackView.addArrangedSubview(ingredientView)
        // 재료 추가 이벤트는 버튼 탭으로만 알림 (텍스트 변경은 제외)
        NotificationCenter.default.post(name: Notification.Name("IngredientChanged"), object: nil)
    }

    @objc func ingredientTextFieldDidChange() {
        // 텍스트 변경 시 NotificationCenter 알림 제거
        // 저장 버튼 탭 시에만 collectIngredients 호출
    }

    func collectIngredients() -> [RecipeIngredient] {
        var ingredients: [RecipeIngredient] = []

        for view in ingredientsStackView.arrangedSubviews {
            guard let nameTextField = view.subviews.first(where: { $0 is UITextField && ($0 as! UITextField).placeholder == "재료명" }) as? UITextField,
                  let name = nameTextField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                continue
            }

            var qty: Double?
            var unit: String?

            for subview in view.subviews {
                if let textField = subview as? UITextField {
                    if textField.placeholder == "1" {
                        if let text = textField.text, let value = Double(text) {
                            qty = value
                        }
                    } else if textField.placeholder == "개" {
                        unit = textField.text?.trimmingCharacters(in: .whitespaces)
                    }
                }
            }

            let ingredient = RecipeIngredient(
                name: name,
                qty: qty,
                unit: unit,
                altText: nil
            )
            ingredients.append(ingredient)
        }

        return ingredients
    }

    func loadIngredients(_ ingredients: [RecipeIngredient]) {
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !ingredients.isEmpty else {
            addInitialIngredient()
            return
        }

        for ingredient in ingredients {
            let ingredientView = createIngredientView()
            ingredientsStackView.addArrangedSubview(ingredientView)

            if let nameTextField = ingredientView.subviews.first(where: { ($0 as? UITextField)?.placeholder == "재료명" }) as? UITextField {
                nameTextField.text = ingredient.name
            }

            if let qty = ingredient.qty {
                for subview in ingredientView.subviews {
                    if let textField = subview as? UITextField, textField.placeholder == "1" {
                        textField.text = String(format: "%g", qty)
                    }
                }
            }

            if let unit = ingredient.unit {
                for subview in ingredientView.subviews {
                    if let textField = subview as? UITextField, textField.placeholder == "개" {
                        textField.text = unit
                    }
                }
            }
        }
    }
}

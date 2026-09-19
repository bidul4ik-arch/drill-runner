extends Node
# Real wallet never accepts local receipts. Native providers send tokens to an authenticated server.
# This desktop build supplies only an explicit test provider. No real money is charged.
var config: Dictionary
func _ready() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://Config/store.json"))
func test_purchase(product: String, outcome: String, transaction: String) -> String:
	if not Profile.test_store: return tr("Тестовый магазин выключен")
	if outcome!="verified":
		if outcome=="pending": Profile.data.test_pending[transaction]=product
		elif outcome=="cancelled": Profile.data.test_pending.erase(transaction)
		Profile.save()
		return {"cancelled":tr("Отменено"),"pending":tr("Ожидает подтверждения"),"failed":tr("Ошибка покупки")}.get(outcome,tr("Не подтверждено"))
	if transaction in Profile.data.test_transactions: return tr("Транзакция уже обработана")
	for pack in config.packages:
		if pack.id==product:
			Profile.data.test_pending.erase(transaction)
			Profile.data.test_transactions.append(transaction)
			Profile.data.test_premium += int(pack.amount)
			Profile.save()
			return tr("Тестовая валюта начислена")
	return tr("Неизвестный товар")
func real_purchase(_product: String) -> String:
	return tr("Недоступно: не подключены магазин и сервер проверки")

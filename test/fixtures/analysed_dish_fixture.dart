import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';

/// Test data for [AnalysedDish]. One factory per [DishVerdict], with distinct
/// field values on every one — `CLAUDE.md` §Testing records what a fixture
/// whose fields share one value hides.
abstract final class AnalysedDishFixture {
  /// A dish suitable as printed.
  static AnalysedDish orderAsIs({
    String name = 'סטייק אנטריקוט',
    String? description = 'עם חמאת עשבי תיבול וברוקולי בחמאה',
    String why = 'בשר ושומן בלבד, ללא רכיבי פחמימה',
  }) => AnalysedDish(
    name: name,
    description: description,
    verdict: DishVerdict.orderAsIs,
    why: why,
  );

  /// A dish that is modifiable — always carries [modification].
  static AnalysedDish modifiable({
    String name = 'המבורגר עם צ׳יפס',
    String? description = 'בקר טחון, לחמנייה, צ׳יפס ורוטב ברביקיו',
    String why = 'הלחמנייה והצ׳יפס עמוסים בפחמימות עמילניות',
    String modification = 'בקשו בלי לחמנייה, עם סלט ירוק במקום הצ׳יפס',
  }) => AnalysedDish(
    name: name,
    description: description,
    verdict: DishVerdict.modifiable,
    why: why,
    modification: modification,
  );

  /// A dish that is structurally non-keto — no [modification] can save it.
  static AnalysedDish nonKeto({
    String name = 'פיצה מרגריטה',
    String? description = 'בצק דק, רוטב עגבניות, מוצרלה ובזיליקום',
    String why = 'הבצק הוא פחמימה מובנית שאי אפשר להסיר מהמנה',
  }) => AnalysedDish(
    name: name,
    description: description,
    verdict: DishVerdict.nonKeto,
    why: why,
  );
}

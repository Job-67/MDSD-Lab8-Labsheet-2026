# ใบงานปฏิบัติสัปดาห์ที่ 8: Local Database & Persistence ด้วย Drift

**วิชา** การพัฒนาซอฟต์แวร์สำหรับอุปกรณ์เคลื่อนที่ | **เครื่องมือ** Flutter, Drift, sqlite3_flutter_libs, build_runner, Google AI Studio

> 🔗 **ความต่อเนื่องของโปรเจกต์:** ใบงานนี้สืบทอดโดยตรงจากโปรเจกต์ **`campus_marketplace_w7`** ที่ทำไว้จนจบใบงานการทดลองที่ 7 ตอนนี้โปรเจกต์มี: หน้า **Home** ที่ดึงสินค้าจริงจาก Fake Store API (สัปดาห์ 6), ตะกร้าสินค้า (`CartModel`, สัปดาห์ 5), หน้า **"ลงประกาศขายสินค้า" (Sell)** ที่ใช้ Gemini Vision ช่วยแนะนำ title/category/description จากรูปภาพ (สัปดาห์ 7) และโครง **Bottom Navigation Bar** (`MainScaffold`) ที่มี 2 Tab แรกคือ "หน้าหลัก" กับ "ลงประกาศขาย"  **ยังไม่มี** ฟีเจอร์ "ถูกใจ" (Favorites) และร่างประกาศที่ AI ช่วยแนะนำ หลังกดยืนยันจะถูกเก็บไว้ใน State ชั่วคราวของ `SellItemPage` เท่านั้น **หายไปทันทีที่ปิดแอป**
>
> สัปดาห์นี้คือจุดที่ฟีเจอร์ **"รายการโปรด" (Favorites) ถูกสร้างขึ้น** พร้อมกันกับการนำร่างประกาศมาบันทึกถาวร ทั้งสองฟีเจอร์จะเข้าถึงข้อมูลผ่าน **Repository Pattern** เช่นเดียวกับที่ `ItemRepository`/`ItemRepositoryApi` ทำกับ REST API ในสัปดาห์ที่ 6 **ทำต่อในโฟลเดอร์ `campus_marketplace_w7` เดิม ห้ามสร้างโปรเจกต์ใหม่แยกต่างหาก** 

---

## วัตถุประสงค์การเรียนรู้

เมื่อทำใบงานนี้เสร็จสิ้น ผู้เรียนจะสามารถ

1. ใช้ AI ช่วยร่างโครงสร้างตาราง (Schema) จากคำอธิบายฟีเจอร์เป็นภาษาธรรมชาติ แล้วประเมิน/ปรับแก้ด้วยตนเอง
2. ติดตั้งและตั้งค่า Drift พร้อมรัน Code Generation ด้วย `build_runner` ได้ถูกต้อง
3. ประกาศตาราง (`Table`) และคลาสฐานข้อมูล (`AppDatabase`) ตามหลักการที่เรียนในบทหนังสือเรียนหัวข้อ 8.4
4. ออกแบบและเขียน Repository Pattern (Interface + Implementation) สำหรับ Local Database เองได้ โดยไม่ต้องมีตัวอย่างสำเร็จรูปครบทุกเมธอด
5. สร้างฟีเจอร์ "ถูกใจ" (Favorites) และนำร่างประกาศขายสินค้าจากสัปดาห์ที่ 7 มาบันทึกถาวรด้วย Drift ได้จริง
6. เพิ่ม Tab ใหม่เข้า Bottom Navigation Bar (`MainScaffold`) ที่มีอยู่แล้วได้ โดยไม่กระทบโค้ดของ Tab เดิม
7. ทดสอบและยืนยันว่าแอปทำงานแบบ Offline-first ได้จริง คือข้อมูลไม่หายแม้ปิดแอปหรือปิดอินเทอร์เน็ต

## สิ่งที่ต้องเตรียมก่อนเริ่ม

- โปรเจกต์ `campus_marketplace_w7` จากใบงานการทดลองที่ 7 ที่รันได้ปกติครบทุก Checkpoint แล้ว (มีหน้า Home, Checkout, Sell พร้อม `MainScaffold` 2 Tab)
- บัญชี Google AI Studio ที่ใช้มาตั้งแต่สัปดาห์ที่ 1
- ติดตั้ง Flutter SDK เวอร์ชันล่าสุดที่รองรับ Null Safety เต็มรูปแบบ (ตรวจสอบด้วย `flutter --version`)

⚠️ **ข้อควรระวัง**: การเปลี่ยนโครงสร้างตาราง (เพิ่ม/ลบ/แก้ไขคอลัมน์) หลังรัน `build_runner` ไปแล้วครั้งหนึ่ง ต้องรันคำสั่งเดิมซ้ำทุกครั้ง มิเช่นนั้นไฟล์ `.g.dart` จะไม่ตรงกับโค้ดล่าสุดและโปรเจกต์จะไม่คอมไพล์ผ่าน หากเจอปัญหานี้ให้ดูหัวข้อ Troubleshooting ท้ายใบงาน

---

## ส่วนที่ 1: ใช้ AI ช่วยร่าง Schema ก่อนเขียนโค้ด

ตามหลักการในบทหนังสือเรียนหัวข้อ 8.3 การออกแบบ Schema ต้องทำก่อนเขียนโค้ดเสมอ สัปดาห์นี้จะฝึกใช้ Gemini ช่วยร่าง Schema เบื้องต้น แล้วนำมาตรวจสอบและปรับแก้ด้วยตนเอง เพราะ AI ช่วยคิดได้เร็ว แต่การตัดสินใจสุดท้ายต้องเป็นของนักพัฒนาเสมอ (หลักการเดียวกับที่เรียนเรื่อง Responsible AI ในสัปดาห์ที่ 7)

### ขั้นตอนที่ 1.1 🔧 ทำตามขั้นตอน

เปิด Google AI Studio (https://aistudio.google.com) แล้วส่ง Prompt นี้ให้ Gemini

```
ฉันกำลังพัฒนาแอป Flutter ชื่อ Campus Marketplace ด้วย Drift (ORM สำหรับ SQLite)
ต้องการออกแบบตารางสองตาราง

1. เก็บรายการสินค้าที่ผู้ใช้กดถูกใจเป็นครั้งแรก 
   ต้องรู้ว่าถูกใจสินค้าชิ้นไหน (อ้างอิงจาก id สินค้าที่เป็นตัวเลข)
   เก็บชื่อ ราคา รูปภาพไว้ด้วยเพื่อแสดงผลได้โดยไม่ต้องเรียก API ซ้ำ และต้องเรียงตามเวลาที่กดถูกใจล่าสุดได้

2. เก็บร่างประกาศขายสินค้าที่ AI ช่วยแนะนำจากรูปภาพ (ปัจจุบันเก็บไว้ใน State ชั่วคราวเท่านั้น หายเมื่อปิดแอป)
   มีชื่อประกาศ หมวดหมู่ คำบรรยาย และ path ของรูปภาพในเครื่อง ต้องรู้ว่าแก้ไขล่าสุดเมื่อไหร่

ช่วยร่างโค้ด Dart ของ Class ที่ extends Table ทั้งสองตาราง พร้อมระบุชนิดข้อมูล (Column type)
ของแต่ละคอลัมน์ และเหตุผลว่าทำไมเลือกชนิดข้อมูลนั้น
```

บันทึกโค้ดที่ Gemini ตอบกลับมาที่ด้านล่าง

```dart
// 1. ตาราง FavoriteItems (สินค้าที่ถูกใจ)
import 'package:drift/drift.dart';

class FavoriteItems extends Table {
  // ใช้ productId จาก API เป็น Primary Key เพื่อป้องกันข้อมูลซ้ำ
  IntColumn get productId => integer()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text()();

  // เก็บเวลาที่กดถูกใจ (ใช้ DateTime)
  DateTimeColumn get favoritedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {productId};
}

// 2. ตาราง DraftListings (ร่างประกาศขายจาก AI)
class DraftListings extends Table {
  // สร้าง ID ใหม่ให้ทุกร่างประกาศเพื่อแยกแยะแต่ละอัน
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get description => text()();

  // เก็บ path ของรูปในเครื่อง (Local Storage Path)
  TextColumn get imageLocalPath => text()();

  // เก็บเวลาที่แก้ไขล่าสุด (ใช้สำหรับจัดลำดับร่างประกาศ)
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

เหตุผลที่ Gemini ให้ไว้: `productId` เป็นตัวเลขตาม id จาก Backend, `price` ใช้ `real` เพราะมีทศนิยม, `imageUrl` และ `imageLocalPath` เก็บเป็นข้อความ, `favoritedAt` และ `updatedAt` ใช้ `DateTime` เพื่อเรียงลำดับตามเวลา พร้อมคำแนะนำให้ตรวจว่าไฟล์รูปยังอยู่จริงก่อนแสดงผล (`File(path).exists()`)

![ผลลัพธ์จาก Gemini ใน Google AI Studio](image/Screenshot%202026-10-03%20164427.png)


### ขั้นตอนที่ 1.2: ตรวจสอบและเทียบกับหลักการในบทเรียน 🧠 คิดเอง

เปรียบเทียบ Schema ที่ได้จาก Gemini กับหลักการในบทเรียนหัวข้อ 8.3 แล้วตอบคำถามต่อไปนี้ โดยการสรุปตามความเข้าใจของตนเอง (ห้ามคัดลอกคำตอบจาก Gemini มาวางตรง ๆ)

- Gemini กำหนด Primary Key ให้แต่ละตารางถูกต้องหรือไม่ (ควรเป็น Auto-increment Integer ตามที่อธิบายในบทเรียน)
- คอลัมน์ราคาสินค้า Gemini เลือกชนิดข้อมูลใด ตรงกับที่บทเรียนแนะนำ (`RealColumn`/`double`) หรือไม่ หากไม่ตรง ให้แก้ไขเอง
- Gemini เสนอให้เก็บสำเนาข้อมูล (เช่น ชื่อ/ราคาสินค้า) ซ้ำไว้ในตาราง Favorites หรือแนะนำให้เก็บแค่ `itemId` แล้วไปเรียก API ใหม่ทุกครั้ง หากแนะนำแบบหลัง ให้อธิบายตามหลักการ Offline-first ในบทหนังสือเรียนหัวข้อ 8.6 ว่าทำไมแนวทางนั้นไม่เหมาะกับสถานการณ์ที่ไม่มีอินเทอร์เน็ต
- Gemini กำหนดให้คอลัมน์ที่อ้างอิงสินค้า (`itemId`) ห้ามมีค่าซ้ำกัน (`.unique()`) หรือไม่ ถ้าไม่ได้กำหนด ให้เพิ่มเอง เพราะถ้าไม่มีข้อบังคับนี้ ผู้ใช้กดหัวใจสินค้าชิ้นเดียวกันซ้ำได้ไม่จำกัด ทำให้ตาราง Favorites มีแถวซ้ำกันสะสมไปเรื่อย ๆ

> ✅ **Checkpoint 1.1** บันทึกคำตอบจากคำถามด้านบนทั้ง 4 ข้อ พร้อมแนบภาพหน้าจอผลลัพธ์จาก Gemini

```text
1. Primary Key: ถูกต้องเพียงบางส่วน
   - DraftListings ใช้ id => integer().autoIncrement()() ถูกต้องตามบทเรียน
   - FavoriteItems ไม่มี id แบบ autoIncrement แต่ใช้ productId (id จาก API) เป็น Primary Key
     ผ่าน primaryKey => {productId} ซึ่งไม่ตรงกับบทเรียนที่ให้ใช้ Auto-increment Integer
     ข้อเสียคือผูกตารางกับ id ภายนอก ถ้า API เปลี่ยนรูปแบบ id จะกระทบ Primary Key ตรง ๆ
     จึงแก้เองเป็น id autoIncrement และแยก itemId ออกมาเป็นอีกคอลัมน์

2. ราคาสินค้า: Gemini เลือก RealColumn (double) ตรงกับที่บทเรียนแนะนำ ไม่ต้องแก้
   เพราะราคามีทศนิยม ถ้าใช้ int จะเสียส่วนทศนิยม ถ้าใช้ text จะเรียงและคำนวณไม่สะดวก

3. เก็บสำเนาหรือเก็บแค่ itemId: Gemini เก็บสำเนา title/price/imageUrl ไว้ในตาราง Favorites
   (ระบุเหตุผลว่าเพื่อ Offline-first) ถือว่าถูกต้อง
   ถ้าเก็บแค่ itemId แล้วเรียก API ใหม่ทุกครั้ง เมื่อไม่มีอินเทอร์เน็ตจะดึงข้อมูลสินค้าไม่ได้
   หน้ารายการโปรดจะว่างหรือ error ทั้งที่ผู้ใช้เคยกดถูกใจไว้แล้ว ขัดกับหลักการ Offline-first (หัวข้อ 8.6)

4. .unique() ที่ itemId: Gemini ไม่ได้ใส่ .unique() แต่กันซ้ำด้วยการตั้ง productId เป็น Primary Key แทน
   ซึ่งได้ผลเท่ากัน แต่เมื่อแก้ให้ใช้ id autoIncrement ตามข้อ 1 ต้องเพิ่มเองเป็น
   IntColumn get itemId => integer().unique()();
   เพราะถ้าไม่มี ผู้ใช้กดหัวใจสินค้าชิ้นเดิมซ้ำได้ไม่จำกัด ตารางจะมีแถวซ้ำสะสมเรื่อย ๆ
   (เมื่อมี unique ต้องใช้ InsertMode.insertOrIgnore ตอน insert เพื่อไม่ให้เกิด UNIQUE constraint failed)

หมายเหตุ: ชื่อที่ Gemini ตั้ง (productId, favoritedAt, DraftListings, imageLocalPath) ต่างจาก Schema ในใบงานส่วนที่ 2
(itemId, addedAt, ListingDrafts, imagePath) ส่วนถัดไปจะใช้ชื่อตามใบงาน
```

![ภาพหน้าจอ Google AI Studio (Gemini 3.1 Flash Lite)](image/Screenshot%202026-10-03%20164427.png)

---

## ส่วนที่ 2: ติดตั้ง Drift และประกาศตาราง

### ขั้นตอนที่ 2.1: ติดตั้งแพ็กเกจ 🔧 ทำตามขั้นตอน

เพิ่ม dependency ในไฟล์ `pubspec.yaml` ของโปรเจกต์ `campus_marketplace_w7` **ต่อจาก** `http`, `provider` และ `image_picker` ที่มีอยู่แล้วจากสัปดาห์ที่ 6-7 (ไม่ต้องลบของเดิม)

```yaml
dependencies:
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.20.0
  build_runner: ^2.4.13
```

รัน `flutter pub get` ในเทอร์มินัล

### ขั้นตอนที่ 2.2: สร้างไฟล์ประกาศตาราง 🔧 ทำตามขั้นตอน

สร้างไฟล์ `lib/database/tables.dart` ตามโครงสร้างในบทเรียนหัวข้อ 8.4 (ใช้ Schema ตามบทเรียน เพื่อให้ตรงกับใบงานการทดลองในส่วนถัดไป )

```dart
import 'package:drift/drift.dart';

class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().unique()(); // .unique() ป้องกันถูกใจสินค้าชิ้นเดียวกันซ้ำ
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ListingDraftRow') // ตั้งชื่อ Class ที่ Generate เอง ดูคำอธิบายด้านล่าง
class ListingDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get description => text()();
  TextColumn get imagePath => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

⚠️ **จุดที่พลาดง่ายมากในสัปดาห์นี้โดยเฉพาะ**: ปกติ Drift จะตั้งชื่อ Class ที่ Generate จากตารางด้วยการตัด `s` ท้ายชื่อ Table ออก (เช่นตาราง `FavoriteItems` → Class `FavoriteItem` ตามที่เรียนในบทหนังสือเรียน) ถ้าปล่อยให้ `ListingDrafts` ทำแบบเดียวกัน Drift จะสร้าง Class ชื่อ `ListingDraft` ออกมา ซึ่ง**ชนกับ Class `ListingDraft` ที่สร้างไว้แล้วตั้งแต่ใบงานการทดลองที่ 7** (เก็บแค่ `title`/`category`/`description` ที่ได้จาก AI ก่อนบันทึก) ทำให้โปรเจกต์มี 2 Class ชื่อเดียวกันคนละความหมายและคอมไพล์ไม่ผ่านเพราะ import ชนกัน Annotation `@DataClassName('ListingDraftRow')` ด้านบนแก้ปัญหานี้โดยสั่งให้ Driftตั้งชื่อ Class ที่ Generate เป็น `ListingDraftRow` แทน 


---

## ส่วนที่ 3: สร้างคลาสฐานข้อมูลหลักและรัน Code Generation

### ขั้นตอนที่ 3.1: สร้าง AppDatabase 🔧 ทำตามขั้นตอน

ดูตัวอย่างโค้ดเต็มในบทเรียนหัวข้อ 8.4 ขั้นตอนที่ 3 แล้วคัดลอกมาสร้างไฟล์ `lib/database/app_database.dart` ของตนเอง (import ตารางจาก `tables.dart` ที่สร้างในส่วนที่ 2 เข้ามาใช้งาน พร้อม `@DriftDatabase(tables: [FavoriteItems, ListingDrafts])`) หากตั้งชื่อ Class ของตารางต่างจากตัวอย่าง ให้แก้ชื่อใน `@DriftDatabase(tables: [...])` ให้ตรงกับชื่อจริงใน `tables.dart` ของตนเองด้วย


### ขั้นตอนที่ 3.2: รัน Code Generation 🔧 ทำตามขั้นตอน

รันคำสั่งต่อไปนี้ในเทอร์มินัลของ VS Code ที่โฟลเดอร์โปรเจกต์

```bash
dart run build_runner build --delete-conflicting-outputs
```

รอจนกระบวนการเสร็จสิ้น ตรวจสอบว่ามีไฟล์ `lib/database/app_database.g.dart` ถูกสร้างขึ้นใหม่ และตรวจสอบใน Debug Console ว่าไม่มี Error เรื่อง Class ชื่อซ้ำ (ถ้าเจอ ให้กลับไปตรวจสอบ ขั้นตอน 2.2 ว่าใส่ `@DataClassName` ไว้ถูกต้องหรือไม่)

### ขั้นตอนที่ 3.3: เชื่อม AppDatabase เข้ากับแอป 🧠 คิดเอง (มีโครงให้)
**นักศึกษาเขียน Code เอง**

สัปดาห์นี้ซับซ้อนกว่าเดิมเล็กน้อย เพราะ `main.dart` ต้องสร้าง `AppDatabase` ขึ้นมาหนึ่งอินสแตนซ์ แล้วส่งต่อให้ Repository **สองตัว** (Favorites และ Draft) ที่จะสร้างในส่วนที่ 4-5 ก่อนส่งเข้า `MainScaffold` อีกที ตรวจสอบตามโครงนี้แล้วเติมส่วนที่ยังไม่มี (Repository ทั้งสองตัวจะสร้างจริงในส่วนถัดไป ตอนนี้แค่เตรียมจุดเชื่อมไว้ก่อน)

```
ในฟังก์ชัน main():
    สร้าง AppDatabase() ขึ้นมา 1 ตัว เก็บไว้ในตัวแปร db

    เรียก runApp() ห่อด้วย ChangeNotifierProvider<CartModel> เหมือนเดิม
    ส่ง db เข้าไปเป็นพารามิเตอร์ของ MyApp (เพิ่ม field ใหม่ใน MyApp รับค่า AppDatabase)

ใน MyApp.build(context):
    สร้าง MainScaffold โดยส่งพารามิเตอร์ 3 ตัวเข้าไป:
        itemRepository: ItemRepositoryApi() (ตัวเดิมจากสัปดาห์ที่ 6-7)
        favoritesRepository: สร้างจาก AppDatabase ที่รับมา (จะเขียน Class จริงในส่วนที่ 4)
        draftRepository: สร้างจาก AppDatabase ตัวเดียวกัน (จะเขียน Class จริงในส่วนที่ 5)
```

> 💡 สังเกตว่า `AppDatabase` ถูกสร้างขึ้น **ครั้งเดียว** ใน `main()` แล้วส่งต่อผ่าน Constructor ไปเรื่อย ๆ (Dependency Injection) หลักการเดียวกับที่ `ItemRepositoryApi()` ถูกสร้างครั้งเดียวแล้วส่งต่อมาตั้งแต่สัปดาห์ที่ 6 — ห้ามสร้าง `AppDatabase()` ใหม่หลายจุดในแอปเดียวกัน เพราะแต่ละอินสแตนซ์จะเปิดการเชื่อมต่อไฟล์ฐานข้อมูลแยกจากกัน ทำให้ข้อมูลที่เขียนจากจุดหนึ่งอาจไม่ปรากฏอีกจุดหนึ่ง

> ✅ **Checkpoint 3.1**

capture หน้าจอผลลัพธ์คำสั่ง `dart run build_runner build` จากขั้นตอนที่ 3.2 ที่แสดงว่าสร้างไฟล์สำเร็จ (ไม่มี Error เรื่อง Class ชื่อซ้ำ) จากนั้นเปิดไฟล์ main.dart ที่แก้ตามขั้นตอนที่ 3.3 โดย ยังไม่ต้องรันแอปในจุดนี้ เพราะ VS Code จะขีดเส้นสีแดงใต้ FavoritesRepositoryDrift และ ListingDraftRepositoryDrift (ยังไม่มี Class จริง จะเขียน Class นี้ในส่วนที่ 4-5) และถ้าสั่งรันตอนนี้แอปจะ Error ทันทีเพราะคอมไพล์ไม่ผ่าน ถือเป็นเรื่องปกติ — จะกลับมารันแอปได้จริงอีกครั้งหลังทำ Checkpoint 4.1 และ 5.1 เสร็จ

```text
ผลคำสั่ง dart run build_runner build --delete-conflicting-outputs
  - รันครั้งแรก: Built with build_runner/aot in 90s; wrote 40 outputs. (สร้างไฟล์ app_database.g.dart สำเร็จ)
  - ภาพด้านล่างเป็นรันครั้งที่สอง: wrote 0 outputs เพราะโค้ดตารางไม่เปลี่ยน build_runner จึงข้ามงาน (80 skipped) ไม่ใช่ข้อผิดพลาด
  - มี warning ว่าแฟลก --delete-conflicting-outputs ถูกถอดออกจาก build_runner เวอร์ชันใหม่และถูกข้าม ไม่กระทบผล

คลาสที่ Generate ใน lib/database/app_database.g.dart:
  FavoriteItem, FavoriteItemsCompanion, ListingDraftRow, ListingDraftsCompanion
  -> ไม่มีคลาส ListingDraft ซ้ำกับของเดิมจากสัปดาห์ที่ 7 เพราะใส่ @DataClassName('ListingDraftRow') แล้ว

main.dart ที่แก้ตามขั้นตอน 3.3:
  final db = AppDatabase();           // สร้างครั้งเดียวใน main()
  runApp(MultiProvider(..., child: MyApp(db: db)));
  // ใน MyApp.build
  MainScaffold(
    itemRepository: ItemRepositoryApi(),
    favoritesRepository: FavoritesRepositoryDrift(db),
    draftRepository: ListingDraftRepositoryDrift(db),
  )
ช่วงนั้น dart analyze มี error เฉพาะที่คาดไว้ คือยังไม่มีคลาส FavoritesRepositoryDrift / ListingDraftRepositoryDrift (เขียนในส่วนที่ 4-5)
```

![ผลคำสั่ง build_runner](image/Screenshot%202026-10-03%20173109.png)

---

## ส่วนที่ 4: สร้างฟีเจอร์ "รายการโปรด" (Favorites) ตั้งแต่ต้น

นี่คือฟีเจอร์ใหม่ทั้งหมดของแอป ประกอบด้วย 4 ส่วนที่ต้องทำให้ครบ คือ 1.Repository 2.ปุ่มกดถูกใจในหน้า Home 3.หน้าจอแสดงรายการโปรด และ 4.การเพิ่ม Tab ที่ 3 เข้า Bottom Navigation Bar

### ขั้นตอนที่ 4.1: สร้าง Repository Interface และ Implementation 
**นักศึกษาเขียน Code เอง**

สร้างไฟล์ `lib/repositories/favorites_repository.dart` (Interface) และ `lib/repositories/favorites_repository_drift.dart` (Implementation) เองทั้งหมด โดยอ้างอิงโครงสร้างและลำดับขั้นตอนจากบทเรียนหัวข้อ 8.4 (ซึ่งสอนตัวอย่างนี้ไว้แบบเต็มทุกบรรทัดอยู่แล้ว) สังเกตว่ารูปแบบนี้เหมือนกับ `ItemRepository`/`ItemRepositoryApi` ในสัปดาห์ที่ 6 ทุกประการ เพียงแค่เปลี่ยนจากการเรียก REST API มาเป็นการเรียก Drift แทน


**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- Interface `FavoritesRepository` ต้องมีอย่างน้อย 3 เมธอด: `addFavorite(int itemId, String title, double price, String imageUrl)`, `getAllFavorites()` (คืนค่า `Future<List<FavoriteItem>>` เรียงจากกดถูกใจล่าสุด), `removeFavorite(int itemId)`
- Class `FavoritesRepositoryDrift implements FavoritesRepository` ต้องรับ `AppDatabase` เข้ามาทาง Constructor (เหมือน `final AppDatabase _db;`)
- ทุกเมธอดต้องเขียนลง/อ่านจาก `_db.favoriteItems` เท่านั้น ห้ามมีโค้ดเรียก `http`/Dio ปะปนอยู่เลย (ตามหลักการ Offline-first หัวข้อ 8.6)
- `getAllFavorites()` ต้องเรียงผลลัพธ์ด้วย `orderBy` ตามคอลัมน์ `addedAt` จากใหม่ไปเก่า
- `addFavorite(...)` ต้องเรียก `.insert(...)` พร้อมระบุ `mode: InsertMode.insertOrIgnore` เพราะคอลัมน์ `itemId` เป็น `.unique()` (Checkpoint 2.1) ถ้าไม่ใส่ การกดหัวใจซ้ำที่สินค้าชิ้นเดิมจะทำให้แอป Error ด้วย `UNIQUE constraint failed` แทนที่จะแค่ไม่มีอะไรเกิดขึ้น

### ขั้นตอนที่ 4.2: เพิ่มปุ่ม "กดถูกใจ" ในหน้า Home 🧠 คิดเอง (มีโครงให้)

แก้ไข `lib/screens/home_page.dart` ให้รับ `FavoritesRepository` เข้ามาทาง Constructor เพิ่มอีก 1 ตัว (คู่กับ `ItemRepository` ที่มีอยู่แล้ว) แล้วเพิ่มไอคอนรูปหัวใจต่อท้ายแต่ละแถวสินค้าใน `ListTile` คู่กับไอคอนตะกร้าที่มีอยู่แล้ว

**แนวทางเขียนโค้ด (Pseudocode)** — ลองไล่ตามลำดับนี้แล้วแปลงเป็น Dart ด้วยตัวเอง

```
ใน HomePage (StatefulWidget):
    เพิ่ม field favoritesRepository ชนิด FavoritesRepository ใน Constructor

ใน trailing ของแต่ละ ListTile (ปัจจุบันมีแค่ปุ่มตะกร้า):
    เปลี่ยนจาก IconButton เดี่ยว เป็น Row ที่มี mainAxisSize: MainAxisSize.min แล้วใส่ 2 ปุ่ม:
        ปุ่มที่ 1: ไอคอนรูปหัวใจ (Icons.favorite_border)
            เมื่อกด → เรียก widget.favoritesRepository.addFavorite(item.id, item.title, item.price, item.imageUrl)
            เนื่องจากเป็น Future ต้องจัดการ error ด้วย try/catch หรือ .catchError() แล้วแสดง SnackBar แจ้งผล (สำเร็จ/ผิดพลาด)
        ปุ่มที่ 2: ปุ่มตะกร้าเดิม (ไม่ต้องแก้ไข)
```

**คำใบ้ / จุดที่ต้องระวัง**

- `addFavorite(...)` เป็น `Future<void>` ดังนั้นฟังก์ชันที่เรียกมันใน `onPressed` ควรเป็น `async` เพื่อ `await` และจับ error ได้ถูกต้อง
- ไม่ต้องเปลี่ยนไอคอนหัวใจให้ทึบ (Toggle สถานะ) ในสัปดาห์นี้ — แค่กดแล้วเพิ่มลงฐานข้อมูลสำเร็จพร้อม SnackBar ยืนยันก็เพียงพอ (การเอาออกจากรายการโปรดทำที่หน้า Favorites โดยเฉพาะในขั้นตอนถัดไป เหมือนกับที่การลบออกจากตะกร้าทำที่หน้า Checkout ไม่ใช่หน้า Home)
- อย่าลืมแก้จุดที่สร้าง `HomePage(...)` ใน `MainScaffold` (ขั้นตอนที่ 4.4) ให้ส่ง `favoritesRepository` เข้าไปด้วย ไม่งั้นจะ Error ว่าพารามิเตอร์ที่จำเป็นหายไป

### ขั้นตอนที่ 4.3: สร้างหน้าจอ "รายการโปรด" (FavoritesPage) 
**นักศึกษาเขียน Code เอง**
สร้างไฟล์ `lib/screens/favorites_page.dart` เป็น `StatefulWidget` ที่รับ `FavoritesRepository` เข้ามาทาง Constructor

**ข้อกำหนดที่ต้องมีครบ:**

- ใช้ `FutureBuilder` เรียก `repository.getAllFavorites()` ใน `initState()` (รูปแบบเดียวกับ `HomePage` ที่เรียก `repository.getItems()` มาตั้งแต่สัปดาห์ที่ 6)
- จัดการ 3 สถานะให้ครบ: กำลังโหลด (`CircularProgressIndicator`), รายการว่างเปล่า (ข้อความแนะนำ เช่น "ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ"), และมีข้อมูล (`ListView.builder` แสดง title/price/imageUrl)
- แต่ละแถวมีปุ่มลบ (`IconButton` ไอคอนถังขยะ) ที่เรียก `repository.removeFavorite(itemId)` แล้ว `setState()` เพื่อโหลดรายการใหม่ (เรียก `getAllFavorites()` ซ้ำแล้วอัปเดต Future ที่ผูกกับ `FutureBuilder`)
- ไม่ต้องรับ `ItemRepository` เข้ามาในหน้านี้ เพราะข้อมูลที่แสดง (title/price/imageUrl) ถูกเก็บสำเนาไว้ในตาราง `FavoriteItems` ครบอยู่แล้วตามที่ออกแบบไว้ในส่วนที่ 1 — ไม่ต้องเรียก Fake Store API ซ้ำ

### ขั้นตอนที่ 4.4: เพิ่ม Tab ที่ 3 เข้า MainScaffold ที่มีอยู่แล้ว 🔧 ทำตามขั้นตอน

ตามที่ `campus_marketplace_lab_roadmap.md` หัวข้อ 2.1 วางแผนไว้ Favorites คือ Tab ที่ 3 ของแอป เปิดไฟล์ `lib/screens/main_scaffold.dart` ที่สร้างไว้แล้วตั้งแต่สัปดาห์ที่ 7 แล้วแก้ไขตามนี้ **ไม่ต้องแก้ไขโค้ดภายใน `HomePage` หรือ `SellItemPage` เพิ่มเติมจากที่ทำในขั้นตอนก่อนหน้านี้**

```dart
// ก่อนแก้
class MainScaffold extends StatefulWidget {
  final ItemRepository repository;
  const MainScaffold({super.key, required this.repository});
  // ...
}
```

```dart
// หลังแก้
class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository; // จะมีจริงหลังทำส่วนที่ 5 เสร็จ
  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  // ...
}
```

และในเมธอด `build`

```dart
// ก่อนแก้
final pages = [
  HomePage(repository: widget.repository),
  const SellItemPage(),
];
// ...
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
  BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
],
```

```dart
// หลังแก้
final pages = [
  HomePage(
    repository: widget.itemRepository,
    favoritesRepository: widget.favoritesRepository,
  ),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
// ...
items: const [
  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
  BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
  BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
],
```

อย่าลืมเพิ่ม `import 'favorites_page.dart';`, `import '../repositories/favorites_repository.dart';` และ `import '../repositories/listing_draft_repository.dart';` ที่หัวไฟล์ และแก้ `lib/main.dart` ให้ส่งพารามิเตอร์ตามชื่อใหม่ (`itemRepository:`, `favoritesRepository:`, `draftRepository:`) ตามโครงที่วางไว้ในขั้นตอนที่ 3.3

> ⚠️ `IndexedStack` อ้างอิง index ตามตำแหน่งใน List `pages` และ `BottomNavigationBarItem` ต้องมีจำนวนเท่ากับ `pages` เสมอ (ตอนนี้ต้องเป็น 3 ทั้งคู่) ถ้าจำนวนไม่ตรงกันแอปจะ Error ทันทีตอนรัน ไม่ใช่แค่แสดงผลผิด

> ✅ **Checkpoint 4.1** รันแอปแล้วทดสอบ: (ก) กดหัวใจที่สินค้า 3 ชิ้นจากหน้า Home (ข) สลับไป Tab "รายการโปรด" เห็นครบทั้ง 3 ชิ้น (ค) ปิดแอปให้สนิท (Force Stop หรือปัดออกจาก Recent Apps) แล้วเปิดใหม่ กลับไปที่ Tab รายการโปรดอีกครั้ง ถ่ายภาพหน้าจอ (ข) และ (ค) เทียบกัน ต้องแสดงรายการเดิมครบทุกชิ้น พร้อมทดสอบกดลบ (Remove) 1 ชิ้น แล้วปิดเปิดแอปใหม่อีกครั้งเพื่อยืนยันว่าการลบก็ถูกบันทึกถาวรเช่นกัน (ง) กลับไปหน้า Home แล้วกดหัวใจซ้ำที่สินค้าชิ้นเดิมอีกครั้ง (ชิ้นที่ยังไม่ได้ลบ) แล้วตรวจสอบที่ Tab รายการโปรดว่ายังแสดงสินค้าชิ้นนั้นแค่แถวเดียว ไม่ซ้ำเป็น 2 แถว และแอปไม่ Error

```text
ทดสอบบนมือถือ vivo V2322 (Android 15) ด้วยข้อมูลสินค้าจำลอง 5 ชิ้น (ItemRepositoryMock) เพราะ Fake Store API ล่มช่วงที่ทดสอบ (HTTP 522)

(ก)-(ข) กดหัวใจสินค้า 3 ชิ้น แล้วสลับไป Tab "รายการโปรด" เห็นครบทั้ง 3 ชิ้น (เวลา 18:11) ปุ่มบนการ์ดเปลี่ยนเป็นหัวใจแดง "ถูกใจแล้ว" (เวลา 18:14)
(ลบ) กดลบ 1 ชิ้น (เป้สะพายหลังนักศึกษา) เหลือ 2 ชิ้น จากนั้นกดถูกใจใหม่ที่หน้าหลัก รายการกลับมา 3 ชิ้น เรียงชิ้นล่าสุดไว้บนสุด ไม่ซ้ำ (เวลา 18:15)
(ค) ภาพหลังปิดแอปสนิทแล้วเปิดใหม่ และ (ง) ภาพกดหัวใจซ้ำชิ้นเดิม: [รอแนบภาพ]
```

![(ข) Tab รายการโปรด 3 ชิ้น 18:11](image/235bbe1c-c7fd-4613-af2d-9e719ca4cde3.jpg)

![หน้าหลัก หัวใจแดง 18:14](image/a36a588e-9505-4f09-bbd1-b36f180ecf1d.jpg)

![หลังลบ 1 ชิ้น เหลือ 2 ชิ้น 18:15](image/5e01f408-af81-45ca-b4b0-b03ec934791a.jpg)

![กดถูกใจเป้สะพายหลังใหม่ 18:15](image/20ea703d-be00-4dc8-bfab-909ebb9ff068.jpg)

![Tab รายการโปรด กลับมา 3 ชิ้น 18:15](image/7ccb3355-e80c-40e1-8810-b0649b41e2fb.jpg)

---

## ส่วนที่ 5: นำร่างประกาศขายสินค้า (สัปดาห์ที่ 7) มาบันทึกถาวร

### ขั้นตอนที่ 5.1: สร้าง Repository สำหรับ Draft 
**นักศึกษาเขียน Code เอง**

สร้างไฟล์ `lib/repositories/listing_draft_repository.dart` (Interface) และ `lib/repositories/listing_draft_repository_drift.dart` (Implementation) ในรูปแบบเดียวกับส่วนที่ 4 ทุกประการ แต่ทำงานกับตาราง `ListingDrafts` แทน

**ข้อกำหนดที่ต้องมีครบ:**

- Interface `ListingDraftRepository` ต้องมีอย่างน้อย 3 เมธอด: `saveDraft(ListingDraft draft, String imagePath)` (บันทึกร่างใหม่ — รับ `ListingDraft` ที่มีอยู่แล้วจากสัปดาห์ 7 บวก path รูปภาพแยกต่างหาก เพราะ `ListingDraft` เดิมไม่มี field นี้), `getAllDrafts()` (คืนค่า `Future<List<ListingDraftRow>>` เรียงจากแก้ไขล่าสุด — สังเกตว่าใช้ `ListingDraftRow` ไม่ใช่ `ListingDraft` ตามที่อธิบายไว้ใน Checkpoint 2.1), และ `deleteDraft(int id)`
- `saveDraft(...)` ต้องดึงค่า `draft.title`, `draft.category`, `draft.description` มาประกอบกับ `imagePath` ที่รับมาแยก แล้วสร้าง `ListingDraftsCompanion.insert(...)` ก่อน `.insert()` ลงฐานข้อมูล

### ขั้นตอนที่ 5.2: แก้ไขหน้า "ลงประกาศขายสินค้า" ให้บันทึกร่างถาวร 🔧 ทำตามขั้นตอน 

เปิดไฟล์ `sell_item_page.dart` จากสัปดาห์ที่ 7 แก้ไข 2 จุด: (1) รับ `ListingDraftRepository` เข้ามาทาง Constructor และ (2) แก้ปุ่ม "ยืนยันร่างประกาศ" (ที่เดิมแค่เก็บค่าไว้ใน State ชั่วคราวตามใบงานสัปดาห์ที่ 7 ส่วนที่ 5.2)

```dart
// ก่อนแก้
class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});
  // ...
}
```

```dart
// หลังแก้
class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});
  // ...
}
```

และในปุ่ม "ยืนยันร่างประกาศ" เปลี่ยนจากการเก็บค่าไว้ในตัวแปร State เฉย ๆ ให้เรียก `await widget.draftRepository.saveDraft(draft, imageFile!.path)` แทน จัดการ Loading/Success/Error ระหว่างบันทึกเช่นเดียวกับที่เคยทำตอนเรียก Gemini Vision ในสัปดาห์ที่ 7 แล้วค่อยแสดง `SnackBar` ยืนยันและล้างฟอร์มเหมือนเดิมหลังบันทึกสำเร็จ

### ขั้นตอนที่ 5.3: สร้างหน้าจอ "ร่างประกาศของฉัน" (My Drafts) 
**นักศึกษาเขียน Code เอง**

สร้างหน้าจอใหม่ `lib/screens/my_drafts_page.dart` ที่รับ `ListingDraftRepository` เข้ามาทางConstructor เรียก `repository.getAllDrafts()` แสดงรายการร่างทั้งหมดที่เคยบันทึกไว้เป็น `ListView` (รูปแบบเดียวกับ `FavoritesPage` ในส่วนที่ 4.3) แต่ละรายการแสดงชื่อประกาศ หมวดหมู่ และวันเวลาที่แก้ไขล่าสุด พร้อมปุ่มลบร่างที่ไม่ต้องการแล้ว จัดการสถานะ Loading/Success/Empty ให้ครบ

**ทำไมหน้านี้ไม่ใช่ Tab ที่ 4**: ตาม `campus_marketplace_lab_roadmap.md` หัวข้อ 2.1 มีกฎชัดเจนว่าอะไรควรเป็น Tab (ปลายทางหลักที่สลับไปมาตลอดเวลา) กับอะไรควรเป็น Push/Pop (Flow เฉพาะกิจที่มีจุดเริ่ม-จบ) "ร่างประกาศของฉัน" เป็นหน้าจัดการร่างที่ผูกกับ Flow การลงประกาศโดยตรง ไม่ใช่ปลายทางหลักที่ผู้ใช้เปิดดูตลอดเวลาเหมือน Favorites อีกทั้ง Roadmap ได้กำหนดไว้แล้วว่า Tab ที่ 4 ของแอปคือ "โปรไฟล์" ในสัปดาห์หน้า การเพิ่ม Tab ใหม่อีกตัวตอนนี้จะทำให้ลำดับ Tab ทั้งเทอมเพี้ยนไปจากแผน **จึงให้เข้าถึงหน้านี้ด้วยปุ่มไอคอนใน AppBar ของ Tab "ลงประกาศขาย" แทน** (เช่น `IconButton(icon: Icon(Icons.history), onPressed: () => Navigator.push(...))`) เพิ่ม `AppBar` ให้ `SellItemPage` ถ้ายังไม่มี แล้วใส่ปุ่มนี้ไว้ที่ `actions`

> ✅ **Checkpoint 5.1** รันแอปแล้วทำตามลำดับนี้: 1. สร้างร่างประกาศใหม่ผ่าน Tab "ลงประกาศขาย" ด้วยความช่วยเหลือของ AI เหมือนสัปดาห์ที่ 7 2. กดยืนยันร่าง 3. กดปุ่มไอคอนเข้าหน้า "ร่างประกาศของฉัน" แล้วเห็นร่างที่เพิ่งสร้าง 4. ปิดแอปให้สนิทแล้วเปิดใหม่ กลับเข้าหน้า "ร่างประกาศของฉัน" อีกครั้ง ถ่ายภาพหน้าจอทั้ง 4 ขั้นตอนนี้แนบส่ง เพื่อพิสูจน์ว่าร่างไม่หายไปแม้ปิดแอปแล้ว 

```text
ทดสอบบนมือถือ vivo V2322 ด้วย Gemini Vision จริง (โมเดล gemini-3.1-flash-lite) ใช้รูปบอร์ด ESP32 บน Breadboard (เวลา 18:31 ทั้งหมด)

1. สร้างร่างด้วย AI: เลือกรูป กด "ให้ AI ช่วยแนะนำ" ได้ชื่อประกาศ "ESP32 พร้อม Breadboard และอุปกรณ์ทดลอง" หมวดหมู่ "อุปกรณ์อิเล็กทรอนิกส์" และคำบรรยาย
2. กด "ยืนยันร่างประกาศ" ขึ้น SnackBar "บันทึกร่างประกาศเรียบร้อยแล้ว" และฟอร์มถูกล้าง
3. กดไอคอนนาฬิกาเข้าหน้า "ร่างประกาศของฉัน" เห็นร่างที่เพิ่งสร้าง พร้อมรูปและเวลาแก้ไขล่าสุด 03/10/2026 18:31
4. ปิดแอปสนิทแล้วเปิดใหม่ ร่างยังอยู่ (ภาพ 18:33 ในหัวข้อ 6.1 ที่เปิดหน้าร่างประกาศหลังเปิดแอปใหม่ แสดงร่างเดิมเวลา 18:31)
```

![1. AI แนะนำชื่อ หมวดหมู่ คำบรรยาย](image/8ff6b460-46d4-42a6-8b92-1ec72298252f.jpg)

![1. ฟอร์มที่ AI กรอกให้ (เลื่อนลง)](image/37f33c8c-a2cf-402c-9525-3a428557ebdb.jpg)

![2. กดยืนยัน บันทึกสำเร็จ](image/1e8f121d-aeaa-4646-91d6-cc5c611cb1eb.jpg)

![3. หน้าร่างประกาศของฉัน 18:31](image/9989681d-0e5e-4b61-90c5-f66f98ecd6e6.jpg)

![4. เปิดแอปใหม่ ร่างยังอยู่ 18:33](image/76bc91e0-37f7-4de1-8d77-5b6097403fa2.jpg)

---

## ส่วนที่ 6: ทดสอบสถานการณ์ Offline-first

### ขั้นตอนที่ 6.1: ปิดอินเทอร์เน็ตแล้วทดสอบ 🔧 ทำตามขั้นตอน

ปิด Wi-Fi และ Data บนอุปกรณ์ทดสอบ แล้วเปิดแอป `campus_marketplace_w7` เข้าไปที่ Tab "รายการโปรด" และหน้า "ร่างประกาศของฉัน"

> ✅ **Checkpoint 6.1** ถ่ายภาพหน้าจอที่แสดงให้เห็นว่า Tab รายการโปรดและหน้าร่างประกาศยังคงแสดงข้อมูลได้ตามปกติแม้ไม่มีอินเทอร์เน็ตเลย (ส่วน Tab หน้าหลักที่ดึงจาก Fake Store API คาดว่าจะแสดง Error ตามปกติ เพราะยังไม่ได้ทำ Local Cache ให้หน้านั้น) 

```text
ปิดอินเทอร์เน็ตด้วยโหมดเครื่องบิน (ไอคอนเครื่องบินที่แถบสถานะ ไม่มีสัญลักษณ์ 4G) แล้วเปิดแอปใหม่ (เวลา 18:33)

- Tab "รายการโปรด" ยังแสดง 4 รายการจากฐานข้อมูลได้ครบ (ชื่อและราคา) ส่วนรูปสินค้าแสดงเป็นไอคอน "ไม่พบรูป" เพราะรูปดึงจาก URL ต้องใช้อินเทอร์เน็ต แอปไม่พัง
- หน้า "ร่างประกาศของฉัน" ยังแสดงร่างพร้อมรูป เพราะรูปเก็บเป็นไฟล์ในเครื่อง
- หน้าหลักในการทดสอบนี้ใช้ข้อมูลจำลองในแอป จึงยังแสดงสินค้าได้ (ถ้าใช้ Fake Store API จริงจะขึ้น error ตามที่ใบงานคาดไว้)
```

![Tab รายการโปรด ออฟไลน์](image/6ccc230d-7414-48b5-bbb6-8076e290ace1.jpg)

![หน้าร่างประกาศของฉัน ออฟไลน์](image/76bc91e0-37f7-4de1-8d77-5b6097403fa2.jpg)

![หน้าหลัก ออฟไลน์ (ข้อมูลจำลอง)](image/7ff2dd29-23fc-4f38-97eb-0970a604e934.jpg)

---

## ปัญหาที่พบบ่อยและวิธีแก้ไข (Troubleshooting)

**Error พูดถึง Class `ListingDraft` ชนกัน หรือ `The name 'ListingDraft' is defined in multiple libraries`** เกิดจากลืมใส่ `@DataClassName('ListingDraftRow')` บนตาราง `ListingDrafts` ใน `tables.dart` ตามที่เตือนไว้ใน Checkpoint 2.1 ทำให้ Drift สร้าง Class ชื่อ `ListingDraft` ซ้ำกับ Class เดิมจากสัปดาห์ที่ 7 ให้เพิ่ม Annotation นี้แล้วรัน `dart run build_runner build --delete-conflicting-outputs` ใหม่อีกครั้ง

**Error: `Target of URI hasn't been generated: 'app_database.g.dart'`** เกิดจากยังไม่ได้รันคำสั่ง `dart run build_runner build --delete-conflicting-outputs` หรือรันแล้วแต่มีข้อผิดพลาดระหว่างสร้างโค้ดที่ยังไม่ได้แก้ไข ให้ตรวจสอบผลลัพธ์ในเทอร์มินัลตอนรันคำสั่งนี้ให้ละเอียด มักมีข้อความบอกบรรทัดที่ผิดพลาดในไฟล์ `tables.dart`

**รัน `build_runner` แล้วค้างนานผิดปกติหรือ error ว่า `Conflicting outputs`** ให้ลองรันคำสั่ง `dart run build_runner clean` ก่อน แล้วค่อยรัน `dart run build_runner build --delete-conflicting-outputs` ใหม่อีกครั้ง

**`The named parameter 'favoritesRepository'/'draftRepository' isn't defined` ตอนแก้ `main_scaffold.dart`/`home_page.dart`/`sell_item_page.dart`** เกิดจากแก้ Constructor ของไฟล์หนึ่งแล้ว แต่ยังไม่ได้แก้จุดที่เรียกใช้ Widget นั้นให้ส่งพารามิเตอร์ใหม่ครบ ให้ไล่ตรวจทั้ง 3 ไฟล์ตามลำดับ: `main.dart` → `main_scaffold.dart` → `home_page.dart`/`sell_item_page.dart` ว่าชื่อพารามิเตอร์ตรงกันทุกจุด

**แอป Error ทันทีตอนเปิด บอกประมาณ `RangeError` หรือ Bottom Navigation Bar กับหน้าจอไม่ตรงกัน** เกิดจากจำนวนรายการใน List `pages` ของ `MainScaffold` ไม่เท่ากับจำนวน `BottomNavigationBarItem` (ต้องเป็น 3 รายการทั้งคู่หลังทำ Checkpoint 4.1) ให้ตรวจนับทั้งสองรายการให้ตรงกัน

**แอป Crash ด้วยข้อความเกี่ยวกับ `sqlite3` ตอนรันบน Android จริง** ตรวจสอบว่าเพิ่ม `sqlite3_flutter_libs` ใน `pubspec.yaml` ครบถ้วนแล้ว และรัน `flutter clean` ตามด้วย `flutter pub get` ใหม่อีกครั้งก่อนรันแอป

**ข้อมูลหายไปหลังแก้ไขโครงสร้างตาราง (เพิ่ม/ลบคอลัมน์)** เกิดจากไม่ได้เพิ่มค่า `schemaVersion` และเขียนโค้ด Migration รองรับ ตามที่เตือนไว้ในบทหนังสือเรียนหัวข้อ 8.4 ระหว่างพัฒนา (ยังไม่ปล่อยให้ผู้ใช้จริงใช้งาน) วิธีแก้ชั่วคราวที่ง่ายที่สุดคือถอนการติดตั้งแอปออกจากอุปกรณ์ทดสอบแล้วติดตั้งใหม่ เพื่อล้างไฟล์ฐานข้อมูลเก่าทิ้ง (ห้ามใช้วิธีนี้กับแอปที่ผู้ใช้จริงติดตั้งอยู่แล้ว)

**หน้า Favorites/My Drafts แสดงค้างที่ Loading ตลอด ไม่ขึ้นข้อมูล** มักเกิดจากลืมเรียก `setState()` หลังจากได้ผลลัพธ์จาก `await repository.getAllFavorites()`/`getAllDrafts()` กลับมา (โดยเฉพาะหลังกดลบแล้วต้องการให้ List รีเฟรช) ตรวจสอบตามรูปแบบเดียวกับที่แก้ปัญหานี้มาแล้วในสัปดาห์ที่ 6

**กดหัวใจที่หน้า Home แล้วไม่มีอะไรเกิดขึ้นเลย ไม่มี Error ด้วย** มักเกิดจากลืม `await` หน้า `addFavorite(...)` หรือลืมเขียนโค้ดแสดง `SnackBar` หลังเรียกสำเร็จ ให้ตรวจสอบว่าฟังก์ชันใน `onPressed` ประกาศเป็น `async` และมี `await` ก่อนเรียก `ScaffoldMessenger.of(context).showSnackBar(...)`

**กดหัวใจซ้ำที่สินค้าชิ้นเดิมแล้วแอป Error ด้วยข้อความเกี่ยวกับ `UNIQUE constraint failed`** เกิดจากลืมใส่ `mode: InsertMode.insertOrIgnore` ตอนเรียก `_db.into(_db.favoriteItems).insert(...)` ใน `addFavorite()` เพราะคอลัมน์ `itemId` ถูกกำหนดเป็น `.unique()` ไว้ใน `tables.dart` (Checkpoint 2.1) ทำให้ Insert ซ้ำ `itemId` เดิมไม่ได้ ให้เพิ่มพารามิเตอร์ `mode: InsertMode.insertOrIgnore` เข้าไปในคำสั่ง `.insert(...)`

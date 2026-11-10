// Bắt nhầm đã xác minh (EH-AMS *.int.spec.ts): giá trị GIẢ theo quy ước tên — phải XANH
const PASSWORD = "mat-khau-dung-2468";
const env = { AUTH_SECRET: "int-test-secret-eh163-inventory" };
const ok = await request(server).post("/auth/login").send({ username, password: "mat-khau-moi-1357" });

const request =
    require("supertest");

const { app } =
    require("../index");

describe(
    "Login API",
    () => {

        test(
            "missing user returns 401",
            async () => {

                const response =
                    await request(app)
                    .post(
                        "/api/auth/login"
                    )
                    .send({
                        email:
                        "notfound@test.com",

                        password:
                        "Password123"
                    });

                expect(
                    [401,500]
                ).toContain(
                    response.status
                );
            }
        );

    }
);
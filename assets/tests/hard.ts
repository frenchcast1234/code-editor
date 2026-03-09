// /* =========================================================
//    Advanced Utility Types
//    ========================================================= */

// type Primitive = string | number | boolean | bigint | symbol | null | undefined;

// type DeepReadonly<T> =
//   T extends Primitive
//     ? T
//     : T extends Array<infer U>
//       ? ReadonlyArray<DeepReadonly<U>>
//       : { readonly [K in keyof T]: DeepReadonly<T[K]> };

// type Nullable<T> = T | null;

// type Optional<T> = {
//   [K in keyof T]?: T[K];
// };

// type Mutable<T> = {
//   -readonly [K in keyof T]: T[K];
// };

// type DeepPartial<T> = {
//   [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
// };

// type ValueOf<T> = T[keyof T];

// type ExtractNestedData<T, K extends keyof T> =
//   T[K] extends Array<infer U> ? U : T[K];

// type AsyncReturnType<T extends (...args: any) => Promise<any>> =
//   T extends (...args: any) => Promise<infer R> ? R : never;


// /* =========================================================
//    API Types
//    ========================================================= */

// interface ApiMeta {
//   timestamp: string;
//   requestId: string;
//   duration?: number;
// }

// interface ApiResponse<T> {
//   status: number;
//   data: T;
//   meta: ApiMeta;
// }

// interface ApiError {
//   message: string;
//   code: number;
//   details?: unknown;
// }


// /* =========================================================
//    Domain Types
//    ========================================================= */

// type Address = {
//   city: string;
//   country: string;
//   zip: string;
// };

// type Profile = {
//   name: string;
//   age: number;
//   tags: string[];
//   addresses: Address[];
// };

// type User = {
//   id: string;
//   profile: Profile[];
// };

// type ComplexData = {
//   users: User[];
// };


// /* =========================================================
//    Logger
//    ========================================================= */

// namespace Logger {

//   export type LogLevel =
//     | "debug"
//     | "info"
//     | "warn"
//     | "error";

//   export interface LogEntry {
//     level: LogLevel;
//     message: string;
//     timestamp: string;
//     context?: Record<string, unknown>;
//   }

//   export class ConsoleLogger {

//     private history: LogEntry[] = [];

//     log(level: LogLevel, message: string, context?: Record<string, unknown>) {

//       const entry: LogEntry = {
//         level,
//         message,
//         timestamp: new Date().toISOString(),
//         context
//       };

//       this.history.push(entry);

//       switch (level) {
//         case "debug":
//           console.debug(message, context);
//           break;
//         case "info":
//           console.info(message, context);
//           break;
//         case "warn":
//           console.warn(message, context);
//           break;
//         case "error":
//           console.error(message, context);
//           break;
//       }
//     }

//     getHistory(): ReadonlyArray<LogEntry> {
//       return this.history;
//     }
//   }
// }

// const logger = new Logger.ConsoleLogger();


// /* =========================================================
//    API Client
//    ========================================================= */

// class ApiClient {

//   constructor(private baseUrl: string) {}

//   async request<T>(path: string): Promise<ApiResponse<T>> {

//     const start = performance.now();

//     try {

//       const response = await fetch(`${this.baseUrl}${path}`);

//       const json = await response.json();

//       const end = performance.now();

//       return {
//         ...json,
//         meta: {
//           ...json.meta,
//           duration: end - start
//         }
//       };

//     } catch (err) {

//       logger.log(
//         "error",
//         "API request failed",
//         { path, err }
//       );

//       throw err;
//     }
//   }
// }


// /* =========================================================
//    Fetch Helper
//    ========================================================= */

// const fetchData = async <
//   T extends object,
//   K extends keyof T
// >(
//   url: string,
//   key: K
// ): Promise<ExtractNestedData<T, K>[]> => {

//   try {

//     const response: ApiResponse<T> =
//       await (await fetch(url)).json();

//     if (response.status !== 200) {

//       throw new Error(
//         `Fetch failed with status ${response.status} ` +
//         `for requestId ${response.meta.requestId} ` +
//         `at ${response.meta.timestamp}`
//       );
//     }

//     return (response.data[key] as unknown)
//       as ExtractNestedData<T, K>[];

//   } catch (err) {

//     console.error(
//       `Error fetching data from ${url}:`,
//       (err as Error).message,
//       err
//     );

//     return [];
//   }
// };


// /* =========================================================
//    Data Utilities
//    ========================================================= */

// function groupBy<T, K extends keyof any>(
//   array: T[],
//   getKey: (item: T) => K
// ): Record<K, T[]> {

//   return array.reduce((acc, item) => {

//     const key = getKey(item);

//     if (!acc[key]) {
//       acc[key] = [];
//     }

//     acc[key].push(item);

//     return acc;

//   }, {} as Record<K, T[]>);
// }


// function unique<T>(array: T[]): T[] {
//   return [...new Set(array)];
// }


// /* =========================================================
//    Mock API (for testing)
//    ========================================================= */

// const mockApiData: ComplexData = {
//   users: Array.from({ length: 10 }).map((_, i) => ({
//     id: `user-${i}`,
//     profile: [
//       {
//         name: `User ${i}`,
//         age: 20 + i,
//         tags: ["typescript", "developer", "user"],
//         addresses: [
//           {
//             city: "Paris",
//             country: "France",
//             zip: "75000"
//           },
//           {
//             city: "Berlin",
//             country: "Germany",
//             zip: "10115"
//           }
//         ]
//       }
//     ]
//   }))
// };


// /* =========================================================
//    Data Processing Pipeline
//    ========================================================= */

// async function processUsers() {

//   const users: DeepReadonly<ComplexData["users"]> =
//     await fetchData<ComplexData, "users">(
//       "https://api.example.com/users",
//       "users"
//     );

//   const namesAndCities: string[] =
//     users.flatMap(user =>
//       user.profile.flatMap(profile =>
//         profile.addresses.map(addr =>
//           `${profile.name} lives in ${addr.city}, ${addr.country} (${addr.zip})`
//         )
//       )
//     );

//   const groupedByCountry =
//     groupBy(namesAndCities, str =>
//       str.split(",")[1].trim()
//     );

//   logger.log("info", "Users processed", {
//     count: users.length
//   });

//   console.log(namesAndCities.join(" | "));

//   return groupedByCountry;
// }


// /* =========================================================
//    Execution
//    ========================================================= */

// (async () => {

//   try {

//     const result = await processUsers();

//     console.log("Grouped Result:", result);

//   } catch (err) {

//     logger.log("error", "Fatal error", {
//       error: err
//     });

//   }

// })();
#!/usr/bin/env node
/**
 * Frontend search validation test
 * Run: node test/javascript/search_test.js
 *
 * Tests:
 * 1. Data format is valid
 * 2. All postal codes are 6 digits
 * 3. Search can find results
 */

const DATA_URL = process.env.DATA_URL || "https://cam-postal.gotabs.net/data.json"

async function runTests() {
  console.log("🧪 Running frontend search tests...\n")

  let passed = 0
  let failed = 0

  // Test 1: Fetch data
  console.log("1. Fetching data from", DATA_URL)
  let data, aliases
  try {
    const response = await fetch(DATA_URL)
    const json = await response.json()
    data = json.data
    aliases = json.aliases
    console.log("   ✅ Data fetched:", data.length, "records,", Object.keys(aliases).length, "aliases\n")
    passed++
  } catch (e) {
    console.log("   ❌ Failed to fetch data:", e.message, "\n")
    failed++
    process.exit(1)
  }

  // Test 2: All codes are 6 digits
  console.log("2. Validating postal code format (6 digits)")
  const invalidCodes = data.filter(d => !d.code || d.code.length !== 6)
  if (invalidCodes.length === 0) {
    console.log("   ✅ All", data.length, "postal codes are valid 6-digit format\n")
    passed++
  } else {
    console.log("   ❌ Found", invalidCodes.length, "invalid codes:")
    invalidCodes.slice(0, 5).forEach(d => console.log("      -", d.code, d.name_en))
    console.log("\n")
    failed++
  }

  // Test 3: Data has required fields
  console.log("3. Validating data structure")
  const requiredFields = ["code", "name_en", "type"]
  const missingFields = data.filter(d => !requiredFields.every(f => d[f]))
  if (missingFields.length === 0) {
    console.log("   ✅ All records have required fields:", requiredFields.join(", "), "\n")
    passed++
  } else {
    console.log("   ❌ Found", missingFields.length, "records with missing fields\n")
    failed++
  }

  // Test 4: Can find Phnom Penh
  console.log("4. Testing search for 'Phnom Penh'")
  const phnomPenh = data.filter(d => d.name_en && d.name_en.toLowerCase().includes("phnom penh"))
  if (phnomPenh.length > 0) {
    console.log("   ✅ Found", phnomPenh.length, "results for 'Phnom Penh'\n")
    passed++
  } else {
    console.log("   ❌ No results found for 'Phnom Penh'\n")
    failed++
  }

  // Test 5: Can find by postal code
  console.log("5. Testing search for code '120000'")
  const byCode = data.filter(d => d.code === "120000")
  if (byCode.length === 1) {
    console.log("   ✅ Found postal code 120000:", byCode[0].name_en, "\n")
    passed++
  } else {
    console.log("   ❌ Could not find postal code 120000\n")
    failed++
  }

  // Test 6: Aliases exist for common landmarks
  console.log("6. Validating common aliases exist")
  const commonAliases = ["bkk1", "russian market", "pub street"]
  const missingAliases = commonAliases.filter(a => !aliases[a])
  if (missingAliases.length === 0) {
    console.log("   ✅ All common aliases present:", commonAliases.join(", "), "\n")
    passed++
  } else {
    console.log("   ❌ Missing aliases:", missingAliases.join(", "), "\n")
    failed++
  }

  // Summary
  console.log("─".repeat(40))
  console.log(`Results: ${passed} passed, ${failed} failed`)

  if (failed > 0) {
    console.log("\n❌ Tests failed! Do not deploy.\n")
    process.exit(1)
  } else {
    console.log("\n✅ All tests passed! Safe to deploy.\n")
    process.exit(0)
  }
}

runTests()

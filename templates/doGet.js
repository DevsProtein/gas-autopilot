/**
 * Web App GET handler
 * Specifies the function to execute via the query parameter "fn"
 * Only allowed functions can be executed (security)
 *
 * Usage: curl "<deployUrl>?fn=runDaily"
 */
function doGet(e) {
  const fnName = (e && e.parameter && e.parameter.fn) || '';

  // List allowed functions here (modify per project)
  const allowedFunctions = {
    runDaily,
    testConfig,
    // Add more functions here
  };

  if (!fnName || !(fnName in allowedFunctions)) {
    return ContentService.createTextOutput(
      JSON.stringify({ error: `Unknown function: ${fnName}. Allowed: ${Object.keys(allowedFunctions).join(', ')}` })
    ).setMimeType(ContentService.MimeType.JSON);
  }

  try {
    const result = allowedFunctions[fnName]();
    return ContentService.createTextOutput(
      JSON.stringify({ ok: true, function: fnName, result: result || null })
    ).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return ContentService.createTextOutput(
      JSON.stringify({ ok: false, function: fnName, error: error.message })
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

#pragma once

#include <EDSDK.h>
#include <QString>

// Formats an EdsError as "EDS_ERR_NAME (0xXXXXXXXX)", falling back to just
// the hex code for values EDSDKErrors.h doesn't define (vendor/reserved
// ranges). EDSDK has no string-conversion API; the table is generated from
// EDSDKErrors.h's #define list.
QString edsErrorToString(EdsError err);

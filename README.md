[1.0.20-1] - 2023-02-08

- WRDN-440 [Preview Image] [Issue PCN virtual] The image title is always "Screen with ticket on".
- WRDN-442 [Issue PCN] Disable icon button Search when VRN input is plank
- WRDN-444 [Offline] Don't send GPS events after sync data
- WRDN-206 Do not stop running in the background at the end of the 2nd shift
- WRDN-459 Wrong time when syncing warden event track GPS to server

[1.0.21-1] - 2023-02-08

- WRDN-489 [Offline] Wrong type of PCN when sync data
- WRDN-490 Update the GPS track correctly according to the current time zone of the device

[1.0.24-1] - 2023-02-13

- WRDN-469 As a PO, I want to improve the offline flow

[1.0.25-1] - 2023-02-14

- WRDN-469 As a PO, I want to improve the offline flow (Complete the offline flow)

[1.0.26-1] - 2023-02-15

- WRDN-525 [Online][first seen] After issue PCN by First seen, don't delete this first seen
- WRDN-494 Disabled VRN and Contravention Type when Issue PCN from First Seen
- WRDN-531 [Online]Do not send any GPS to Warden admin
- WRDN-529 [Online]Parking charges Issued data not updating after issue PCN
- WRDN-527 [Online][first seen] Can't check duplicate VRN
- WRDN-468 As a POM, I want the time date in OFFLINE MODE and ONLINE MODE must be the same each other.

[1.0.27-1] - 2023-02-15

- WRDN-528 [Online][overstaying] Can't check permit of VRN
- WRDN-535 [Online]Should sync data after every refresh
- WRDN-550 Display wrong status when sync the first seen, grace period and contravention before checking to the zone
- WRDN-553 Can't display the warden name if have no network
- WRDN-558 [Check in] [Online] Can not get the last updated shift
- WRDN-559 [ONLINE] [Create First seen] Black screen when I click Complete & add

[1.0.28-1] - 2023-02-15

- WRDN-547 [Online] Data should be sorted by expiration time
- WRDN-539 [Online] Can't auto sync data after issue PCN

[1.0.29-1] - 2023-02-16

- WRDN-569 Real time type pcn when refresh, rate when add first seen
- WRDN-524 [Print] Can't get rates value from Stella
- WRDN-566 [Weak network] Wrong data when changing location/zone

[1.0.30-1] - 2023-02-16

- WRDN-557 Wrong status of check GPS although turn off GPS
- WRDN-552 [Weak network]Unable to display static
- WRDN-530 [Print]Distorted content when printing many times.
- WRDN-542 [Weak network] Can't issue PCN
- WRDN-555 [Weak network] Notify error when issue PCN
- WRDN-544 [Weak network] Can't find information by VRN

[1.0.31-1] - 2023-02-17

- WRDN-530 [Print]Distorted content when printing many times.
- WRDN-583 [List Parking charges] Duplicate on refresh during sync data
- WRDN-568 [Avatar] Cannot get avatar of PO
- WRDN-452 [Printer issue] - Multiple pages printed & misalignment
- WRDN-573 Change of information message
- WRDN-574 Error message
- WRDN-576 Heading change

[1.0.32-1] - 2023-02-20

- WRDN-586 The data is still not synchronized when the car has been carLeft in the Grace period
- WRDN-565 Can't get First seen/Grace period image when issue PCN
- WRDN-439 [Physical PCN] some printers start print garbage
- WRDN-590 [SHOWSTOPPER] Sync error

[1.0.33-1] - 2023-02-21

- WRDN-575 Bluetooth enable question
- WRDN-487 [Tabs Active- Expired] Wrong style

[1.0.34-1] - 2023-02-21

- WRDN-589 [Weak network] Can't next to step 2 when issue PCN
- WRDN-570 [Create First seen/Consideration] Should not validate VRN after click Complete & Add

[1.0.35-1] - 2023-02-21

- WRDN-602 Go to step 2 when the license cannot be checked

[1.0.36-1] - 2023-02-21

- WRDN-610 If make the "Car Left", it still display on the expired list
- WRDN-603 Real time contravention reason when refresh home page
- WRDN-608 The way to calculate the expire time of first seen is not correct

[1.0.37-1] - 2023-02-21

- WRDN-613 After create the first seen we do the car left immediatly => the UI still appear item with synced status

[1.0.38-1] - 2023-02-22

- WRDN-609 Should be possible to raise an another First seen within 24 hours if: car already left and have no PCN issued with 24 hours

[1.0.39-1] - 2023-02-22

- WRDN-619 Can't create PCN if have no network

[1.0.40-1] - 2023-02-23

- WRDN-617 VRN field validation can only enter up to 10 characters
- WRDN-605 Change Warden event create PCN from APP to BE

[1.0.41-1] - 2023-02-23

- WRDN-622 [Connect device] text is over than screen
- WRDN-625 Show all assigned rota for the day

[1.0.42-1] - 2023-02-24

- WRDN-615 Only sync data from the server when the user refreshes the page

[1.0.43-1] - 2023-02-24

- WRDN-419 As a PO, I want force the users upgrade the application when have new versions. (Test)

[1.0.44-1] - 2023-02-28

- WRDN-322 Can't login when installing a new app over an existing app

[1.0.45-1] - 2023-02-28

- WRDN-623 As a PO, I want to upgrade the new version without uninstall & clean the local data

[1.0.46-1] - 2023-02-28

- WRDN-601 As a PO, I want to sync the server time to the client side when the user login to the app.

[1.0.47-1] - 2023-03-01

- WRDN-637 The correct time zone is not displayed when changing the machine's time zone
- WRDN-638 Timezone format is wrong when sending to the server

[1.0.48-1] - 2023-03-01

- WRDN-648 Can't send gps to warden admin
- WRDN-636 It is still possible to start a shift even if the required field is showing an error

[1.0.49-1] - 2023-03-01

- WRDN-651 As a developer, I want to refactor the sync process to make sure when one item break. The other data still can send to the server
- WRDN-650 Wrong time displaying pcn's creation date when not in sync

[1.0.50-1] - 2023-03-01

- re-build version 1.0.49

[1.0.51-1] - 2023-03-01

- WRDN-653 The expired time is display negative on the first seen and grace period page

[1.0.52-1] - 2023-03-02

- WRDN-656 Wrong display of server time sync status when first installing the app
- WRDN-655 Change the display of the time change notification when the user taps out and back into the app

[1.0.53-1] - 2023-03-02

- WRDN-662 Edit contravention display time to event date time

[1.0.54-1] - 2023-03-03

- WRDN-663 Show error can't choose rota when offline mode

[1.0.55-1] - 2023-03-07

- WRDN-661 Can't realtime rates in issue PCN screen
- WRDN-652 Can't realtime Contravention reasons in Home and issue PCN screen
- WRDN-493 [Flash] Should turn the flash off when not using camera

[1.2.0-1] - 2023-03-09

- WRDN-422 As a PO, when I create a first seen or consideration period I want to see if a permit exists for that VRN.
- WRDN-692 As a verifier, I should be notified if a VRN has a permit on the verification page

[1.2.1-1] - 2023-03-10

- WRDN-700 [Remain] - Fix UI of "Check permit" button
- WRDN-664 [Issue PCN] Unable to check permit of VRN when user goes back to edit VRN in step 1

[1.2.2-1] - 2023-03-13

- WRDN-460 Improvement Future - iTicket location list should match the cluster list.
- WRDN-722 [Issue PCN] PCN cannot be generated if the user checks the permit without entering the required fields
- WRDN-723 [First seen/Grace period] Only check the permit once, if already checked, it will be added directly.

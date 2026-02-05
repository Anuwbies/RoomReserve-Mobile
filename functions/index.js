const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Translation Map for Notifications
 */
const translations = {
  "en": {
    "org_approved_title": "Organization Approved!",
    "org_approved_body": (name) => `You are now a member of ${name}.`,
    "org_declined_title": "Request Declined",
    "org_declined_body": (name) => `Your request to join ${name} was declined.`,
    "org_kicked_title": "Membership Removed",
    "org_kicked_body": (name) => `You have been removed from ${name}.`,
    "booking_approved_title": "Booking Approved!",
    "booking_approved_body": (name) =>
      `Your reservation for ${name} is confirmed.`,
    "booking_declined_title": "Booking Declined",
    "booking_declined_body": (name) =>
      `Your reservation for ${name} was declined by the administrator.`,
    "booking_cancelled_title": "Booking Cancelled",
    "booking_cancelled_body": (name) =>
      `Your reservation for ${name} has been cancelled.`,
    "booking_completed_title": "Booking Completed",
    "booking_completed_body": (name) =>
      `Your session in ${name} has ended. Thank you!`,
    "upcoming_title": "Upcoming Reservation",
    "upcoming_body": (name, time) =>
      `Your reservation for ${name} starts at ${time}.`,
    "session_starting_title": "Session Starting Now",
    "session_starting_body": (name) =>
      `Your session in ${name} is starting. You can head there now!`,
    "session_ending_title": "10-Minute Warning",
    "session_ending_body": (name) =>
      `Your session in ${name} will end in 10 minutes.`,
    "room_added_title": "New Room Available!",
    "room_added_body": (name) =>
      `${name} has been added to the list of available rooms.`,
  },
  "ja": {
    "org_approved_title": "承認されました！",
    "org_approved_body": (name) => `${name}のメンバーになりました。`,
    "org_declined_title": "リクエスト拒否",
    "org_declined_body": (name) =>
      `${name}への参加リクエストが拒否されました。`,
    "org_kicked_title": "メンバーシップ解除",
    "org_kicked_body": (name) => `${name}から削除されました。`,
    "booking_approved_title": "予約承認！",
    "booking_approved_body": (name) => `${name}の予約が確定しました。`,
    "booking_declined_title": "予約拒否",
    "booking_declined_body": (name) =>
      `${name}の予約は管理者によって拒否されました。`,
    "booking_cancelled_title": "予約キャンセル",
    "booking_cancelled_body": (name) =>
      `${name}の予約がキャンセルされました。`,
    "booking_completed_title": "予約完了",
    "booking_completed_body": (name) =>
      `${name}でのセッションが終了しました。ありがとうございます！`,
    "upcoming_title": "間もなく開始される予約",
    "upcoming_body": (name, time) =>
      `${name}の予約が${time}に開始されます。`,
    "session_starting_title": "セッション開始",
    "session_starting_body": (name) =>
      `${name}でのセッションが始まります。移動してください。`,
    "session_ending_title": "あと10分で終了",
    "session_ending_body": (name) =>
      `${name}でのセッションはあと10分で終了します。`,
    "room_added_title": "新しい部屋が追加されました！",
    "room_added_body": (name) =>
      `${name}が利用可能な部屋に追加されました。`,
  },
  "ko": {
    "org_approved_title": "조직 승인됨!",
    "org_approved_body": (name) => `이제 ${name}의 멤버입니다.`,
    "org_declined_title": "요청 거절됨",
    "org_declined_body": (name) => `${name} 가입 요청이 거절되었습니다.`,
    "org_kicked_title": "멤버십 삭제됨",
    "org_kicked_body": (name) => `${name}에서 삭제되었습니다.`,
    "booking_approved_title": "예약 승인됨!",
    "booking_approved_body": (name) => `${name} 예약이 확정되었습니다.`,
    "booking_declined_title": "예약 거절됨",
    "booking_declined_body": (name) =>
      `${name} 예약이 관리자에 의해 거절되었습니다.`,
    "booking_cancelled_title": "예약 취소됨",
    "booking_cancelled_body": (name) => `${name} 예약이 취소되었습니다.`,
    "booking_completed_title": "예약 완료됨",
    "booking_completed_body": (name) =>
      `${name}에서의 세션이 종료되었습니다. 감사합니다!`,
    "upcoming_title": "예정된 예약",
    "upcoming_body": (name, time) => `${name} 예약이 ${time}에 시작됩니다.`,
    "session_starting_title": "세션 시작됨",
    "session_starting_body": (name) =>
      `${name} 세션이 시작됩니다. 지금 이동하세요!`,
    "session_ending_title": "10분 전 알림",
    "session_ending_body": (name) =>
      `${name} 세션이 10분 후에 종료됩니다.`,
    "room_added_title": "새로운 방 이용 가능!",
    "room_added_body": (name) =>
      `${name}이(가) 이용 가능한 방 목록에 추가되었습니다.`,
  },
  "fil": {
    "org_approved_title": "Aprobado ang Organisasyon!",
    "org_approved_body": (name) => `Miyembro ka na ng ${name}.`,
    "org_declined_title": "Tinanggihan ang Kahilingan",
    "org_declined_body": (name) =>
      `Ang iyong kahilingan na sumali sa ${name} ay tinanggihan.`,
    "org_kicked_title": "Tinanggal sa Membership",
    "org_kicked_body": (name) => `Ikaw ay tinanggal na mula sa ${name}.`,
    "booking_approved_title": "Aprobado ang Pag-book!",
    "booking_approved_body": (name) =>
      `Ang reservasyon sa ${name} ay kumpirmado na.`,
    "booking_declined_title": "Tinanggihan ang Pag-book",
    "booking_declined_body": (name) =>
      `Ang iyong reservasyon para sa ${name} ay tinanggihan ng administrador.`,
    "booking_cancelled_title": "Kinansela ang Pag-book",
    "booking_cancelled_body": (name) =>
      `Ang iyong reservasyon para sa ${name} ay kinansela na.`,
    "booking_completed_title": "Tapos na ang Pag-book",
    "booking_completed_body": (name) =>
      `Tapos na ang session sa ${name}. Salamat!`,
    "upcoming_title": "Darating na Reservasyon",
    "upcoming_body": (name, time) =>
      `Ang reservasyon para sa ${name} ay magsisimula sa ganap na ${time}.`,
    "session_starting_title": "Magsisimula na ang Session",
    "session_starting_body": (name) =>
      `Magsisimula na ang iyong session sa ${name}. Maaari ka nang pumunta!`,
    "session_ending_title": "10-Minutong Paalala",
    "session_ending_body": (name) =>
      `Matatapos na ang iyong session sa ${name} sa loob ng 10 minuto.`,
    "room_added_title": "May Bagong Silid!",
    "room_added_body": (name) =>
      `Ang ${name} ay naidagdag na sa listahan ng mga bakanteng silid.`,
  },
};

/**
 * Helper to get user language
 * @param {string} userId The ID of the user.
 * @return {Promise<string>} The language code.
 */
async function getUserLang(userId) {
  const userDoc = await admin.firestore()
      .collection("users").doc(userId).get();
  if (userDoc.exists) {
    const data = userDoc.data();
    return data.languageCode || "en";
  }
  return "en";
}

/**
 * Helper to send push notifications to all user devices.
 * @param {string} userId The ID of the user.
 * @param {string} title The notification title.
 * @param {string} body The notification body.
 * @param {string} type The notification type.
 * @return {Promise<null>}
 */
async function sendPush(userId, title, body, type) {
  const tokensSnapshot = await admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();

  if (tokensSnapshot.empty) return null;

  const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

  const message = {
    notification: {title, body},
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: type,
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokensSnapshot.docs[idx].ref.delete());
        }
      });
      await Promise.all(failedTokens);
    }
  } catch (error) {
    console.error("Error sending push:", error);
  }
  return null;
}

/**
 * Trigger: When a membership status changes.
 */
exports.onMembershipStatusChange = functions.firestore
    .document("memberships/{membershipId}")
    .onUpdate(async (change, context) => {
      const newData = change.after.data();
      const prevData = change.before.data();
      const userId = newData.userId;

      if (newData.status === prevData.status) return null;

      const lang = await getUserLang(userId);
      const t = translations[lang] || translations["en"];
      const orgName = newData.organizationName;

      let title = "";
      let body = "";
      let titleKey = "";
      let bodyKey = "";

      if (newData.status === "approved") {
        title = t.org_approved_title;
        body = t.org_approved_body(orgName);
        titleKey = "notif_org_approved_title";
        bodyKey = "notif_org_approved_body";
      } else if (newData.status === "declined") {
        title = t.org_declined_title;
        body = t.org_declined_body(orgName);
        titleKey = "notif_org_declined_title";
        bodyKey = "notif_org_declined_body";
      } else if (newData.status === "kicked") {
        title = t.org_kicked_title;
        body = t.org_kicked_body(orgName);
        titleKey = "notif_org_removed_title";
        bodyKey = "notif_org_removed_body";
      } else {
        return null;
      }

      await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("notifications")
          .add({
            title: title,
            body: body,
            titleKey: titleKey,
            bodyKey: bodyKey,
            type: "organization",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
          });

      return sendPush(userId, title, body, "organization_update");
    });

/**
 * Trigger: When a booking status changes.
 */
exports.onBookingStatusChange = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change, context) => {
      const newData = change.after.data();
      const prevData = change.before.data();
      const userId = newData.userId;

      if (newData.status === prevData.status) return null;

      const lang = await getUserLang(userId);
      const t = translations[lang] || translations["en"];
      const roomName = newData.roomName || "Room";

      let title = "";
      let body = "";
      let titleKey = "";
      let bodyKey = "";

      if (newData.status === "approved") {
        title = t.booking_approved_title;
        body = t.booking_approved_body(roomName);
        titleKey = "notif_booking_approved_title";
        bodyKey = "notif_booking_approved_body";
      } else if (newData.status === "declined") {
        title = t.booking_declined_title;
        body = t.booking_declined_body(roomName);
        titleKey = "notif_booking_declined_title";
        bodyKey = "notif_booking_declined_body";
      } else if (newData.status === "cancelled") {
        title = t.booking_cancelled_title;
        body = t.booking_cancelled_body(roomName);
        titleKey = "notif_booking_cancelled_title";
        bodyKey = "notif_booking_cancelled_body";
      } else if (newData.status === "completed") {
        title = t.booking_completed_title;
        body = t.booking_completed_body(roomName);
        titleKey = "notif_booking_completed_title";
        bodyKey = "notif_booking_completed_body";
      } else {
        return null;
      }

      await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("notifications")
          .add({
            title: title,
            body: body,
            titleKey: titleKey,
            bodyKey: bodyKey,
            type: "booking",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
          });

      return sendPush(userId, title, body, "booking_update");
    });

/**
 * Trigger: Runs every 10 minutes to find upcoming reservations.
 */
exports.notifyUpcomingReservations = functions.pubsub
    .schedule("every 10 minutes")
    .onRun(async (context) => {
      const now = admin.firestore.Timestamp.now();
      const in30Mins = admin.firestore.Timestamp.fromMillis(
          now.toMillis() + 30 * 60 * 1000,
      );

      const snapshot = await admin.firestore().collection("bookings")
          .where("status", "==", "approved")
          .where("startTime", "<=", in30Mins)
          .where("startTime", ">", now)
          .where("upcomingNotifSent", "==", false)
          .get();

      if (snapshot.empty) return null;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const userId = data.userId;
        const roomName = data.roomName || "Room";

        const lang = await getUserLang(userId);
        const t = translations[lang] || translations["en"];

        const startTimeStr = data.startTime.toDate().toLocaleTimeString([], {
          hour: "2-digit",
          minute: "2-digit",
        });

        const title = t.upcoming_title;
        const body = t.upcoming_body(roomName, startTimeStr);

        await doc.ref.update({upcomingNotifSent: true});

        await admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
              title: title,
              body: body,
              titleKey: "notif_upcoming_title",
              bodyKey: "notif_upcoming_body",
              type: "booking",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              read: false,
            });

        await sendPush(userId, title, body, "upcoming_booking");
      }

      return null;
    });

/**
 * Trigger: Runs every 5 minutes to find starting and ending bookings.
 */
exports.notifyBookingReminders = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      const now = admin.firestore.Timestamp.now();
      const in5Mins = admin.firestore.Timestamp.fromMillis(
          now.toMillis() + 5 * 60 * 1000,
      );
      const in15Mins = admin.firestore.Timestamp.fromMillis(
          now.toMillis() + 15 * 60 * 1000,
      );
      const in10Mins = admin.firestore.Timestamp.fromMillis(
          now.toMillis() + 10 * 60 * 1000,
      );

      const bookingsRef = admin.firestore().collection("bookings");

      // 1. Session Starting Now (starts in the next 5 mins)
      const startingSoon = await bookingsRef
          .where("status", "==", "approved")
          .where("startTime", "<=", in5Mins)
          .where("startTime", ">", now)
          .where("startNotifSent", "==", false)
          .get();

      for (const doc of startingSoon.docs) {
        const data = doc.data();
        const userId = data.userId;
        const roomName = data.roomName || "Room";
        const lang = await getUserLang(userId);
        const t = translations[lang] || translations["en"];

        const title = t.session_starting_title;
        const body = t.session_starting_body(roomName);

        await doc.ref.update({startNotifSent: true});
        await admin.firestore()
            .collection("users").doc(userId)
            .collection("notifications").add({
              title, body,
              titleKey: "notif_session_starting_title",
              bodyKey: "notif_session_starting_body",
              type: "booking",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              read: false,
            });
        await sendPush(userId, title, body, "session_starting");
      }

      // 2. 10-Minute Warning (ends in the next 10-15 mins)
      const endingSoon = await bookingsRef
          .where("status", "==", "approved")
          .where("endTime", "<=", in15Mins)
          .where("endTime", ">", in10Mins)
          .where("endNotifSent", "==", false)
          .get();

      for (const doc of endingSoon.docs) {
        const data = doc.data();
        const userId = data.userId;
        const roomName = data.roomName || "Room";
        const lang = await getUserLang(userId);
        const t = translations[lang] || translations["en"];

        const title = t.session_ending_title;
        const body = t.session_ending_body(roomName);

        await doc.ref.update({endNotifSent: true});
        await admin.firestore()
            .collection("users").doc(userId)
            .collection("notifications").add({
              title, body,
              titleKey: "notif_session_ending_title",
              bodyKey: "notif_session_ending_body",
              type: "booking",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              read: false,
            });
        await sendPush(userId, title, body, "session_ending");
      }

      return null;
    });

/**
 * Trigger: When a new room is added.
 */
exports.onNewRoomAdded = functions.firestore
    .document("artifacts/default-app-id/public/data/rooms/{roomId}")
    .onCreate(async (snap, context) => {
      const roomData = snap.data();
      const roomName = roomData.name;

      const membersSnapshot = await admin.firestore()
          .collection("memberships")
          .where("status", "==", "approved")
          .get();

      if (membersSnapshot.empty) return null;

      const userIds = [
        ...new Set(membersSnapshot.docs.map((doc) => doc.data().userId)),
      ];

      for (const userId of userIds) {
        const lang = await getUserLang(userId);
        const t = translations[lang] || translations["en"];

        const title = t.room_added_title;
        const body = t.room_added_body(roomName);

        await admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
              title: title,
              body: body,
              titleKey: "notif_room_added_title",
              bodyKey: "notif_room_added_body",
              type: "room_added",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              read: false,
            });

        await sendPush(userId, title, body, "new_room_added");
      }

      return null;
    });

/**
 * Trigger: Runs every 5 minutes to find finished bookings.
 */
exports.autoCompleteBookings = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      const now = admin.firestore.Timestamp.now();
      const bookingsRef = admin.firestore().collection("bookings");

      const snapshot = await bookingsRef
          .where("status", "==", "approved")
          .where("endTime", "<=", now)
          .get();

      if (snapshot.empty) return null;

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: "completed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      return null;
    });

// 콘솔에 메시지 출력
console.log("Javascript 연결 성공")

// 페이지 요소를 찾아 내용 변경
const para = document.getElementById("message")     //html의 <body> 실행 x 때문
para.textContent = "Javascript가 실행되었습니다."    //para.textContent == null
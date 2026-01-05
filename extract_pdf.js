const fs = require('fs');
const path = require('path');
const pdfjsLib = require('pdfjs-dist/legacy/build/pdf.mjs');

async function extractPDF() {
    const pdfPath = path.resolve('./docs/跨平台影音處理與播放 SDK 設計報告.pdf');
    const dataBuffer = new Uint8Array(fs.readFileSync(pdfPath));

    try {
        const loadingTask = pdfjsLib.getDocument({ data: dataBuffer });
        const pdf = await loadingTask.promise;

        console.log('=== PDF 内容提取 ===');
        console.log('頁數:', pdf.numPages);
        console.log('\n=== 文字内容 ===\n');

        let fullText = '';

        for (let i = 1; i <= pdf.numPages; i++) {
            const page = await pdf.getPage(i);
            const textContent = await page.getTextContent();
            const pageText = textContent.items.map(item => item.str).join(' ');
            fullText += `\n--- 第 ${i} 頁 ---\n${pageText}\n`;
            console.log(`--- 第 ${i} 頁 ---`);
            console.log(pageText);
        }

        // Save to file
        fs.writeFileSync('./docs/pdf_content.txt', fullText, 'utf8');
        console.log('\n\n内容已儲存到 ./docs/pdf_content.txt');

    } catch (error) {
        console.error('Error:', error);
    }
}

extractPDF();

const Tesseract = require('tesseract.js');
const fs = require('fs');
const path = require('path');

async function recognizeImage(imagePath) {
    try {
        console.log(`🔍 正在识别图片：${imagePath}`);
        
        const result = await Tesseract.recognize(
            imagePath,
            'eng+chi_sim',
            {
                logger: m => {
                    if (m.status === 'recognizing text') {
                        process.stdout.write(`\r 进度：${Math.round(m.progress * 100)}%`);
                    }
                }
            }
        );
        
        console.log('\n✅ 识别完成！\n');
        console.log('='.repeat(60));
        console.log(result.data.text);
        console.log('='.repeat(60));
        
        return result.data.text;
    } catch (error) {
        console.error('❌ 识别失败:', error.message);
        process.exit(1);
    }
}

// 获取命令行参数
const imagePath = process.argv[2];

if (!imagePath) {
    console.log('用法：node ocr-image.js <图片路径>');
    console.log('示例：node ocr-image.js /path/to/image.jpg');
    process.exit(1);
}

if (!fs.existsSync(imagePath)) {
    console.error(`❌ 文件不存在：${imagePath}`);
    process.exit(1);
}

recognizeImage(imagePath);

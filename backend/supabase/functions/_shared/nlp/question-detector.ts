/**
 * Detects unanswered questions in conversations
 */

export interface UnansweredQuestion {
  message_id: string;
  question_text: string;
  question_type: string; // when, where, what, who, why, how, yes/no
  context: string;
  asked_at: number;
  confidence: number;
}

export class QuestionDetector {
  /**
   * Find unanswered questions in conversation
   */
  async findUnansweredQuestions(
    messages: Array<{ id: string; body: string; sender_id: string; created_at: number }>,
    currentUserId: string
  ): Promise<UnansweredQuestion[]> {
    const unanswered: UnansweredQuestion[] = [];

    for (let i = messages.length - 1; i >= 0; i--) {
      const message = messages[i];
      
      // Only check questions FROM others TO user
      if (message.sender_id === currentUserId) {
        continue;
      }

      // Check if message contains question
      if (!message.body.includes('?')) {
        continue;
      }

      // Check if user responded after this question
      const hasResponse = messages
        .slice(i + 1)
        .some(m => m.sender_id === currentUserId);

      if (!hasResponse) {
        // Extract question type
        const questionType = this.detectQuestionType(message.body);
        
        unanswered.push({
          message_id: message.id,
          question_text: message.body,
          question_type: questionType,
          context: this.extractContext(messages, i),
          asked_at: message.created_at,
          confidence: 0.9,
        });
      }
    }

    return unanswered;
  }

  /**
   * Detect question type
   */
  private detectQuestionType(text: string): string {
    const lowerText = text.toLowerCase();

    if (lowerText.startsWith('when ')) return 'when';
    if (lowerText.startsWith('where ')) return 'where';
    if (lowerText.startsWith('what ')) return 'what';
    if (lowerText.startsWith('who ')) return 'who';
    if (lowerText.startsWith('why ')) return 'why';
    if (lowerText.startsWith('how ')) return 'how';
    
    // Check for yes/no questions
    const yesNoIndicators = ['can you', 'could you', 'would you', 'will you', 'do you', 'are you'];
    if (yesNoIndicators.some(indicator => lowerText.includes(indicator))) {
      return 'yes/no';
    }

    return 'other';
  }

  /**
   * Extract context around question
   */
  private extractContext(
    messages: Array<{ body: string }>,
    questionIndex: number
  ): string {
    const contextRange = 2;
    const start = Math.max(0, questionIndex - contextRange);
    const contextMessages = messages.slice(start, questionIndex);
    
    return contextMessages.map(m => m.body).join(' ');
  }
}


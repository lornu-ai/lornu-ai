import { ContactForm } from '../components/ContactForm';

export default function Contact() {
	return (
		<div className="container mx-auto px-4 py-8">
			<h1 className="text-3xl font-bold">Contact Us</h1>
			<p className="mt-4">
				We'd love to hear from you. Please fill out the form below and we'll get back to you as soon as possible.
			</p>
			<div className="mt-8">
				<ContactForm />
			</div>
		</div>
	);
}
